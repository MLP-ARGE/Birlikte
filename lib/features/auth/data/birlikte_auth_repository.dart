import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_config/app_open_tracker.dart';
import '../../../core/birlikte_api/birlikte_api_client.dart';
import '../../../core/birlikte_api/birlikte_session_provider.dart';
import '../../../core/device/device_identity_provider.dart';
import '../../../core/push/push_notification_service.dart';
import '../../home/application/home_providers.dart';
import '../../home/presentation/widgets/missing_info_sheet.dart';
import '../../profile/data/profile_stats.dart';
import '../presentation/kvkk_popup.dart';
import 'interest_repository.dart';
import 'profile_repository.dart';

/// Giriş akışının hataları — ekranın kullanıcıya ne göstereceğini belirler.
enum AuthFailure {
  /// TC kimlik no / doğum tarihi uyuşmuyor (`KAYIT_BULUNAMADI`).
  invalidCredentials,

  /// Kayıtta doğum tarihi ve/veya cep telefonu eksik (`BILGI_EKSIK`) —
  /// OTP hiç gönderilmiyor, tekrar denemenin anlamı yok: kurumla
  /// (İK/öğrenci işleri) iletişime geçilmesi gerekiyor.
  missingInfo,

  /// SMS kodu yanlış veya süresi dolmuş.
  invalidCode,

  /// Oturum başka bir cihazdan kapatıldı ya da süresi doldu.
  sessionExpired,

  /// Ağ veya sunucu hatası.
  network,
}

class AuthException implements Exception {
  const AuthException(this.failure, [this.message, this.eksikBilgiler = const []]);

  final AuthFailure failure;
  final String? message;

  /// Yalnızca [AuthFailure.missingInfo] için dolu: `"DOGUM_TARIHI"` ve/veya
  /// `"TELEFON"`.
  final List<String> eksikBilgiler;

  @override
  String toString() => 'AuthException($failure, $message)';
}

/// SMS gönderildi. İkinci adım bu kimlikle sürüyor.
class OtpChallenge {
  const OtpChallenge({required this.smsGuid, required this.gecerlilikSaniye});

  final String smsGuid;

  /// Kodun geçerlilik süresi (sn) — geri sayım için.
  final int gecerlilikSaniye;
}

/// Doğrulama sonucu — ekranın SMS sonrası ne göstereceğine karar vermesi
/// için gereken bayraklar.
class VerifyResult {
  const VerifyResult({
    required this.kvkkOnayGerekli,
    required this.kapatilanCihazlar,
  });

  final bool kvkkOnayGerekli;

  /// Bu girişle kapanan diğer cihazların adları — kullanıcıya "diğer
  /// cihazındaki oturum kapatıldı" bilgisini vermek için.
  final List<String> kapatilanCihazlar;
}

/// Giriş akışı — MLPCARE Birlikte mobil API'si (birlikte-api) üzerinden.
///
/// TC kimlik no + doğum tarihi ile SMS istenir, kod doğrulanır.
///
/// Supabase KULLANILMIYOR. İlk tasarımda kupon/puan/kan bağışı Supabase'de
/// kalacağı için RLS'nin ihtiyaç duyduğu bir oturum köprüsü kuruluyordu;
/// birlikte-api'nin kapsamı kupon/puan/kan bağışını da içerecek şekilde
/// genişleyince (bkz. "Kupon, Puan & Kan Bağışı" bölümü) bu köprüye
/// gerek kalmadı — uygulamanın artık tek kimlik kaynağı bu API.
/// Token Edge Function arkasında gizlenmiyor; cihazda (Keychain/
/// EncryptedPrefs) tutuluyor ve tüm çağrılar doğrudan bu token'la yapılıyor.
class BirlikteAuthRepository {
  const BirlikteAuthRepository(
    this._api,
    this._device,
    this._ref, {
    String? appVersion,
  }) : _appVersion = appVersion;

  final BirlikteApiClient _api;
  final BirlikteDeviceIdentity? _device;
  final Ref _ref;

  /// Kurulu sürüm (`1.2.3`) — backend kullanıcı takibi için istiyor,
  /// opsiyonel (bkz. [BirlikteApiClient.verifyOtp]).
  final String? _appVersion;

  Future<OtpChallenge> requestOtp({
    required String kimlikNo,
    required String dogumTarihi,
  }) async {
    try {
      final veri = await _api.requestOtp(
        kimlikNo: kimlikNo,
        dogumTarihi: dogumTarihi,
      );
      return OtpChallenge(
        smsGuid: veri['smsGuid'] as String,
        gecerlilikSaniye: (veri['gecerlilikSaniye'] as num).toInt(),
      );
    } on BirlikteApiException catch (e) {
      if (e.code == 'BILGI_EKSIK') {
        // Kayıtta doğum tarihi ve/veya telefon eksik — OTP hiç
        // gönderilmedi, tekrar denemenin anlamı yok. Mesaj sunucudan
        // geldiği gibi gösterilebilir (kurumla iletişime geç yönlendirmesi
        // zaten metnin içinde).
        final eksik = (e.veri?['eksikBilgiler'] as List<dynamic>? ?? [])
            .cast<String>();
        throw AuthException(AuthFailure.missingInfo, e.message, eksik);
      }
      // `KAYIT_BULUNAMADI` dahil bu uçtaki diğer her ret kimlik/doğum
      // tarihi uyuşmazlığı demek. Metni sunucudan geldiği gibi gösteriyoruz.
      throw AuthException(AuthFailure.invalidCredentials, e.message);
    } on BirlikteApiNetworkException catch (e) {
      throw AuthException(AuthFailure.network, e.message);
    }
  }

  Future<VerifyResult> verifyOtp({
    required String smsGuid,
    required String code,
  }) async {
    final device = _device;
    if (device == null) {
      throw const AuthException(
        AuthFailure.network,
        'cihaz kimliği hazır değil',
      );
    }

    final Map<String, dynamic> veri;
    try {
      veri = await _api.verifyOtp(
        smsGuid: smsGuid,
        kod: code,
        cihazId: device.cihazId,
        cihazAdi: device.cihazAdi,
        platform: device.platform,
        surum: _appVersion,
      );
    } on BirlikteApiException catch (e) {
      // İki kod belgeli (OTURUM_SONLANDI, BASKA_CIHAZDAN_GIRIS); bu uçta
      // gelebilecek diğer her şey (yanlış/süresi dolmuş kod) kullanıcı
      // hatası sayılıyor, metni sunucudan geldiği gibi gösteriyoruz.
      final failure = switch (e.code) {
        'OTURUM_SONLANDI' || 'BASKA_CIHAZDAN_GIRIS' =>
          AuthFailure.sessionExpired,
        _ => AuthFailure.invalidCode,
      };
      throw AuthException(failure, e.message);
    } on BirlikteApiNetworkException catch (e) {
      throw AuthException(AuthFailure.network, e.message);
    }

    final kapatilan = (veri['kapatilanCihazlar'] as List<dynamic>? ?? [])
        .map((d) => (d as Map<String, dynamic>)['cihazAdi'] as String? ?? '?')
        .toList();

    // Token zaten BirlikteApiClient.verifyOtp içinde SecureStorage'a
    // yazıldı; router'ın yönlendirme kararını hemen verebilmesi için
    // oturum bayrağını burada senkron olarak da güncelliyoruz — SecureStorage
    // okumasının asenkron gecikmesini beklemiyoruz.
    _ref.read(birlikteSessionProvider.notifier).set(value: true);

    // `signOut()`'taki invalidate token zaten silinmişken tetiklenir: Home
    // sekmesi (bottom-nav IndexedStack'te canlı kalan branch'lerden biri)
    // hâlâ dinliyorsa, invalidate'in tetiklediği anlık yeniden-fetch tokensiz
    // anında hata verir ve Riverpod "hatada önceki veriyi koru" davranışıyla
    // ESKİ hesabın verisini `.value`'da KALICI olarak saklar — bir sonraki
    // girişte kimse tekrar invalidate etmediği sürece ekran hep eski hesabı
    // gösterir. Çözüm: burada, token zaten yazılmışken (fetch garantili
    // başarılı) TEKRAR invalidate ediyoruz — bu kez gerçek bir yenileme olur.
    invalidateAccountScopedState(_ref);

    // Giriş tamamlanır tamamlanmaz (ekranın build'ini beklemeden) push izni
    // istenir ve verilmişse token backend'e kaydedilir. Aynı oturumda
    // Welcome/Home'daki `ensurePushTokenSynced` bunu tekrar tetiklemez —
    // `syncPushTokenNow` oturum bayrağını hemen işaretliyor.
    unawaited(syncPushTokenNow(_ref));

    final kvkkOnayGerekli = veri['kvkkOnayGerekli'] as bool? ?? false;
    // Welcome'daki onay kutusu işaretlendiğinde okunacak — ayrı bir KVKK
    // ekranı yok, onay kutusunun kendisi bu kaydı tetikliyor (bkz.
    // `kvkk_popup.dart`).
    _ref.read(pendingKvkkOnayProvider.notifier).set(kvkkOnayGerekli);

    return VerifyResult(
      kvkkOnayGerekli: kvkkOnayGerekli,
      kapatilanCihazlar: kapatilan,
    );
  }

  Future<void> signOut() async {
    // Token hâlâ geçerliyken (yetkili bir çağrı) sunucudaki push kaydı
    // siliniyor — aksi halde çıkış yapmış kullanıcıya bildirim gitmeye
    // devam eder.
    await _ref.read(pushNotificationServiceProvider).clear();
    await _api.logout();
    _ref.read(birlikteSessionProvider.notifier).set(value: false);
    invalidateAccountScopedState(_ref);
  }
}

/// Bir sonraki girişin FARKLI bir hesap olabileceğini varsayıyoruz — hesaba
/// özel her şey burada temizleniyor, aksi halde yeni hesap eski hesabın
/// önbelleğe alınmış verisini (profil, ailem, kampanyalar, ...) görmeye
/// devam eder. Cihaza bağlı olanlara (favoriler, cihaz kimliği) bilerek
/// dokunulmuyor.
///
/// Hem manuel çıkışta ([BirlikteAuthRepository.signOut]) hem de oturumun
/// sunucu tarafında sonlanmasında ([handleSessionExpired]) çağrılıyor —
/// ikisinin de sonucu aynı: hesaba özel önbellek geçersiz.
void invalidateAccountScopedState(Ref ref) {
  ref.invalidate(profileProvider);
  ref.invalidate(interestCatalogProvider);
  ref.invalidate(profileStatsProvider);
  ref.invalidate(pointsSummaryAsyncProvider);
  ref.invalidate(campaignsAsyncProvider);
  ref.invalidate(bloodRequestsAsyncProvider);
  ref.invalidate(couponsAsyncProvider);
  ref.invalidate(familyMembersAsyncProvider);
  resetMissingInfoPrompt(ref);
  resetPushSyncFlag(ref);
  resetAppOpenRecordedFlag(ref);
}

/// Refresh token da geçersiz çıktığında (`BirlikteSessionExpiredException` —
/// örn. yukarıdaki `OTURUM_SONLANDI`) [BirlikteApiClient] bunu çağırır:
/// oturum bayrağı düşer (router kullanıcıyı otomatik login'e atar) ve
/// hesaba özel önbellek temizlenir — aksi halde login ekranına düşen
/// kullanıcı, az önce çıkış yaptığı hesabın verisini bir sonraki girişte
/// hâlâ önbellekte bulurdu.
void handleSessionExpired(Ref ref) {
  ref.read(birlikteSessionProvider.notifier).set(value: false);
  invalidateAccountScopedState(ref);
}

final birlikteAuthRepositoryProvider = Provider<BirlikteAuthRepository>((ref) {
  final device = ref.watch(deviceIdentityProvider).value;
  final appVersion = ref.watch(appVersionStringProvider).value;
  return BirlikteAuthRepository(
    ref.watch(birlikteApiClientProvider),
    device,
    ref,
    appVersion: appVersion,
  );
});
