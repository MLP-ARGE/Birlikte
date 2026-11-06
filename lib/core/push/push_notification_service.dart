import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../birlikte_api/birlikte_api_client.dart';

/// Push bildirimi izni isteme ve FCM token'ını birlikte-api'ye
/// (`POST`/`DELETE /api/me/push-token`) senkronize etme.
///
/// Firebase config dosyaları (`google-services.json` / `GoogleService-Info.
/// plist`) projeye eklenene kadar `Firebase.initializeApp()` (bkz.
/// `main.dart`) başarısız olur; bu sınıf o durumda da güvenle çağrılabilir —
/// her adım kendi hatasını yutar, push bildirimleri sessizce devre dışı
/// kalır, uygulamanın geri kalanı etkilenmez.
class PushNotificationService {
  PushNotificationService(this._api);

  final BirlikteApiClient _api;

  /// Sunucu kuralı: `pushToken` en az 20 karakter. Bariz bozuk bir değeri
  /// göndermemek için istemci tarafında da kontrol ediyoruz.
  static const _minTokenLength = 20;

  // `getToken`/`onTokenRefresh` firebase_messaging 17'de `register()`/
  // `onRegistered` lehine deprecated edildi — ama o yeni API klasik FCM
  // kayıt token'ı yerine Firebase Installation ID (FID) döndürüyor, farklı
  // bir kavram. Backend klasik FCM token bekliyor (spesifikasyon: "fcm-veya-
  // apns-token"), bu yüzden pubspec.yaml'da firebase_messaging bilinçli
  // olarak 16.x'e kilitlendi — bu metodlar burada hâlâ doğru API.

  StreamSubscription<String>? _refreshSub;

  /// Girişten sonra (ya da oturum zaten açıkken uygulama her açıldığında)
  /// bir kez çağrılır: izin ister, verilmişse (ya da zaten verilmişse)
  /// token'ı kaydeder ve token yenilendikçe (cihaz/uygulama güncellemesi
  /// gibi durumlarda FCM token'ı değişebilir) tekrar gönderir.
  Future<void> syncIfPermitted() async {
    // `FirebaseMessaging.instance` erişimi bile senkron olarak
    // `[core/no-app]` fırlatıyor Firebase kurulu değilken — bu yüzden tüm
    // gövde try/catch içinde, yalnızca `requestPermission()` çağrısı değil.
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      debugPrint('🔔 push: izin durumu = ${settings.authorizationStatus}');

      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!granted) {
        debugPrint('🔔 push: izin verilmedi, token gönderilmeyecek');
        return;
      }

      await _sendCurrentToken();

      await _refreshSub?.cancel();
      _refreshSub = messaging.onTokenRefresh.listen(_save);
    } catch (e) {
      debugPrint('Push izni/senkronizasyonu atlandı (Firebase henüz kurulu olmayabilir): $e');
    }
  }

  Future<void> _sendCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('🔔 push: FCM token = $token');
      if (token != null) await _save(token);
    } catch (e) {
      debugPrint('FCM token alınamadı: $e');
    }
  }

  Future<void> _save(String token) async {
    if (token.length < _minTokenLength) {
      debugPrint('🔔 push: token çok kısa ($token), gönderilmedi');
      return;
    }
    try {
      await _api.savePushToken(token);
      debugPrint('🔔 push: token backend\'e kaydedildi');
    } catch (e) {
      debugPrint('Push token kaydedilemedi: $e');
    }
  }

  /// Çıkışta çağrılır — sunucudaki kayıt silinmezse çıkış yapmış kullanıcıya
  /// bildirim gitmeye devam eder.
  Future<void> clear() async {
    await _refreshSub?.cancel();
    _refreshSub = null;
    try {
      await _api.deletePushToken();
    } catch (e) {
      debugPrint('Push token silinemedi: $e');
    }
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>(
  (ref) => PushNotificationService(ref.watch(birlikteApiClientProvider)),
);

/// Oturum başına bir kez: izin iste + token'ı senkronize et.
///
/// Sonucu beklemiyoruz (fire-and-forget) — izin isteği native bir sistem
/// diyaloğu açabilir, bu yüzden çağrıldığı ekranın akışını bloklamıyoruz.
/// Bayrağı `build()` SIRASINDA değil `addPostFrameCallback` içinde
/// güncelliyoruz — aynı dersi `missing_info_sheet.dart`'ta zaten "Tried to
/// modify a provider while the widget tree was building" hatasıyla öğrendik.
class _PushSynced extends Notifier<bool> {
  @override
  bool build() => false;

  void markDone() => state = true;
}

final _pushSyncedProvider = NotifierProvider<_PushSynced, bool>(_PushSynced.new);

/// Girişin tamamlandığı an (ör. `verifyOtp` başarılı olduğunda) doğrudan
/// çağrılır — izin isteği ve token senkronizasyonu ekranın `build()`'ını
/// beklemeden hemen başlar. Oturum başına bir kez çalışacak bayrağı burada
/// işaretliyoruz ki [ensurePushTokenSynced] (Welcome/Home'da) aynı oturumda
/// tekrar tetiklemesin.
Future<void> syncPushTokenNow(Ref ref) async {
  debugPrint('🔔 push: syncPushTokenNow çağrıldı');
  ref.read(_pushSyncedProvider.notifier).markDone();
  await ref.read(pushNotificationServiceProvider).syncIfPermitted();
}

/// Girişten geçmeden doğrudan Home'a düşen (oturumu zaten açık) dönen
/// kullanıcılar için: her uygulama açılışında bir kez senkronize eder.
/// Çıkışta çağrılır — bayrak sıfırlanmazsa bir sonraki (farklı hesap olası)
/// girişte push token hiç yeniden gönderilmez.
void resetPushSyncFlag(Ref ref) {
  ref.invalidate(_pushSyncedProvider);
}

void ensurePushTokenSynced(WidgetRef ref) {
  if (ref.read(_pushSyncedProvider)) {
    debugPrint('🔔 push: bu oturumda zaten senkronize edildi, atlanıyor');
    return;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (ref.read(_pushSyncedProvider)) return;
    ref.read(_pushSyncedProvider.notifier).markDone();
    debugPrint('🔔 push: ensurePushTokenSynced tetiklendi');
    unawaited(ref.read(pushNotificationServiceProvider).syncIfPermitted());
  });
}
