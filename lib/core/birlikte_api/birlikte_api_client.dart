import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/data/birlikte_auth_repository.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import 'birlikte_api_logging_client.dart';

/// birlikte-api'nin hata kodu olarak döndürdüğü sonuç.
///
/// `responseStatus: false` olan her yanıt buraya düşer; `code` alanı
/// `responseCode`'un kendisi (örn. "GECERSIZ_KOD", "OTURUM_SONLANDI").
class BirlikteApiException implements Exception {
  const BirlikteApiException(this.code, this.message, {this.httpStatus, this.veri});

  final String code;
  final String message;
  final int? httpStatus;

  /// Bazı hata kodları (örn. YETERSIZ_PUAN) ek alanlarla gelir
  /// (`bakiye`/`gereken` gibi) — çağıran taraf ihtiyaç duyarsa buradan okur.
  final Map<String, dynamic>? veri;

  @override
  String toString() => 'BirlikteApiException($code, $message)';
}

/// Sunucu veya ağ hatası — kullanıcı kodu ilgilendirmeyen durumlar.
class BirlikteApiNetworkException implements Exception {
  const BirlikteApiNetworkException(this.message);
  final String message;
}

/// Oturum kalıcı olarak geçersiz — yeniden giriş gerekiyor.
///
/// Refresh de başarısız olduğunda (örn. `OTURUM_SONLANDI`,
/// `BASKA_CIHAZDAN_GIRIS`) fırlatılır. Çağıran taraf bunu yakalayıp
/// kullanıcıyı giriş ekranına yönlendirmeli.
class BirlikteSessionExpiredException implements Exception {
  const BirlikteSessionExpiredException(this.code);
  final String code;
}

/// MLPCARE Birlikte mobil API istemcisi.
///
/// Her yanıt aynı zarfta gelir: `{ responseStatus, responseCode,
/// responseMessage, veri }` — bu sınıf zarfı açıp `veri`yi döner,
/// `responseStatus: false` olanı [BirlikteApiException] olarak fırlatır.
///
/// PDKS'nin aksine bu API doğrudan mobil istemci için tasarlandı (cihaz/
/// oturum yönetimi buna göre kurulu); bu yüzden PDKS'de olduğu gibi her
/// çağrıyı bir Edge Function'ın arkasına gizlemek yerine token cihazda
/// (Keychain/EncryptedPrefs) tutuluyor ve istemci doğrudan konuşuyor.
/// birlikte-api tek backend: kampanya, ilgi alanı, kupon, puan ve kan bağışı
/// da buradan geliyor — Supabase'e köprü kurmaya gerek yok.
class BirlikteApiClient {
  BirlikteApiClient(this._http, this._storage, {void Function()? onSessionExpired})
      : _onSessionExpired = onSessionExpired;

  final http.Client _http;
  final SecureStorageService _storage;

  /// Oturum kalıcı olarak geçersiz çıktığında (bkz. [_authorized]) bir kez
  /// çağrılır — hesaba özel önbelleği temizleyip kullanıcıyı login'e atmak
  /// çağıranın değil, burasının sorumluluğu: aksi halde her ekran/repository
  /// kendi 401'ini ayrı ayrı ele almak zorunda kalır ve biri unutulursa
  /// kullanıcı sessizce "takılı" kalır (bkz. `OTURUM_SONLANDI` vakası).
  final void Function()? _onSessionExpired;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${AppConfig.birlikteApiUrl}$path').replace(
        queryParameters: query,
      );

  Map<String, String> get _jsonHeaders => const {
    'Content-Type': 'application/json',
  };

  /// Zarfı açar; `responseStatus: false` ise [BirlikteApiException] fırlatır.
  dynamic _unwrap(http.Response res) {
    late final Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      throw BirlikteApiNetworkException('Sunucu yanıtı okunamadı: $e');
    }

    final status = body['responseStatus'] as bool? ?? false;
    final code = body['responseCode'] as String? ?? 'BILINMEYEN';
    final message = body['responseMessage'] as String? ?? '';

    if (!status) {
      throw BirlikteApiException(
        code,
        message,
        httpStatus: res.statusCode,
        veri: body['veri'] as Map<String, dynamic>?,
      );
    }
    return body['veri'];
  }

  // ------------------------------------------------------------- kimlik yok
  // Bu uçlar token istemiyor; giriş öncesi çağrılıyor.

  Future<Map<String, dynamic>> appConfig({
    required String platform,
    required String surum,
  }) async {
    final res = await _http
        .get(_uri('/api/app/config', {'platform': platform, 'surum': surum}))
        .timeout(AppConfig.connectTimeout);
    return _unwrap(res) as Map<String, dynamic>;
  }

  /// Adım 1: kimlik bilgileriyle SMS iste.
  ///
  /// `kimlikTipi: 'PASAPORT'` olduğunda `kimlikUlke` zorunlu; `'TC'`'de
  /// gönderilmez.
  Future<Map<String, dynamic>> requestOtp({
    required String kimlikNo,
    required String dogumTarihi,
    String kimlikTipi = 'TC',
    String? kimlikUlke,
  }) async {
    final res = await _http
        .post(
          _uri('/api/auth/otp/request'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'kimlikTipi': kimlikTipi,
            'kimlikNo': kimlikNo,
            'dogumTarihi': dogumTarihi,
            if (kimlikUlke != null) 'kimlikUlke': kimlikUlke,
          }),
        )
        .timeout(AppConfig.connectTimeout);
    return _unwrap(res) as Map<String, dynamic>;
  }

  /// Adım 2: SMS kodunu doğrular. Başarılıysa token'ları KENDİSİ kaydeder —
  /// çağıran tarafın ayrıca `saveTokens` çağırmasına gerek yok.
  ///
  /// `surum` opsiyonel (backend: "göndermezseniz hiçbir şey bozulmaz") —
  /// uygulamanın kurulu sürümünü (`1.2.3` biçiminde) kullanıcı takibi için
  /// sunucuya bildirir.
  Future<Map<String, dynamic>> verifyOtp({
    required String smsGuid,
    required String kod,
    required String cihazId,
    required String cihazAdi,
    required String platform,
    String? surum,
  }) async {
    final res = await _http
        .post(
          _uri('/api/auth/otp/verify'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'smsGuid': smsGuid,
            'kod': kod,
            'cihazId': cihazId,
            'cihazAdi': cihazAdi,
            'platform': platform,
            if (surum != null) 'surum': surum,
          }),
        )
        .timeout(AppConfig.connectTimeout);
    final veri = _unwrap(res) as Map<String, dynamic>;
    await _storage.saveTokens(
      accessToken: veri['accessToken'] as String,
      refreshToken: veri['refreshToken'] as String,
    );
    return veri;
  }

  Future<void> logout() async {
    final token = await _storage.readAccessToken();
    if (token == null) return;
    try {
      await _http
          .post(
            _uri('/api/auth/logout'),
            headers: {..._jsonHeaders, 'Authorization': 'Bearer $token'},
          )
          .timeout(AppConfig.connectTimeout);
    } catch (_) {
      // Sunucuya ulaşılamasa bile yerel oturumu temizlemek daha önemli;
      // kullanıcı zaten çıkış yapmayı bekliyor.
    }
    await _storage.clearSession();
  }

  // ------------------------------------------------------- yetkili istekler

  Future<String> _refreshToken() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null) {
      throw const BirlikteSessionExpiredException('OTURUM_YOK');
    }
    final http.Response res;
    try {
      res = await _http
          .post(
            _uri('/api/auth/refresh'),
            headers: _jsonHeaders,
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(AppConfig.connectTimeout);
    } catch (e) {
      throw BirlikteApiNetworkException(e.toString());
    }

    if (res.statusCode == 401) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final code = body['responseCode'] as String? ?? 'OTURUM_SONLANDI';
      await _storage.clearSession();
      throw BirlikteSessionExpiredException(code);
    }

    final veri = _unwrap(res) as Map<String, dynamic>;
    final access = veri['accessToken'] as String;
    await _storage.saveTokens(
      accessToken: access,
      // Her yenilemede refreshToken DEĞİŞİYOR (dokümantasyonun kendi
      // uyarısı); en son geleni saklamazsak bir sonraki yenileme düşer.
      refreshToken: veri['refreshToken'] as String,
    );
    return access;
  }

  /// Bearer token ekler; 401 gelirse bir kez `refresh` deneyip isteği
  /// tekrarlar. Refresh de başarısızsa [BirlikteSessionExpiredException]
  /// fırlatır — çağıran taraf kullanıcıyı giriş ekranına yönlendirmeli.
  Future<dynamic> _authorized(
    Future<http.Response> Function(String token) send,
  ) async {
    try {
      var token = await _storage.readAccessToken();
      if (token == null) {
        throw const BirlikteSessionExpiredException('OTURUM_YOK');
      }

      var res = await send(token).timeout(AppConfig.connectTimeout);
      if (res.statusCode == 401) {
        token = await _refreshToken();
        res = await send(token).timeout(AppConfig.connectTimeout);
      }
      return _unwrap(res);
    } on BirlikteSessionExpiredException {
      // Tek nokta: hangi uç/ekran çağırmış olursa olsun, oturum kalıcı
      // olarak geçersizse önbellek temizlenip login'e düşülüyor — çağıran
      // tarafın ayrıca bunu ele alması gerekmiyor (bkz. [_onSessionExpired]).
      _onSessionExpired?.call();
      rethrow;
    }
  }

  /// Girişteki kişinin tüm aktif kayıtları — aynı kişi hem çalışan hem
  /// öğrenci hem yakın olabilir, `veri` bu yüzden bir DİZİ (`kayitTipi` ile
  /// ayrılır), tek bir nesne değil.
  Future<List<dynamic>> me({int kampanyaSayisi = 10}) async {
    final veri = await _authorized(
      (token) => _http.get(
        _uri('/api/me', {'kampanyaSayisi': '$kampanyaSayisi'}),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return veri as List<dynamic>;
  }

  Future<void> completeMissingInfo({required String cinsiyet}) async {
    await _authorized(
      (token) => _http.patch(
        _uri('/api/me/bilgiler'),
        headers: {..._jsonHeaders, 'Authorization': 'Bearer $token'},
        body: jsonEncode({'cinsiyet': cinsiyet}),
      ),
    );
  }

  Future<List<dynamic>> yakinlar() async {
    final veri = await _authorized(
      (token) => _http.get(
        _uri('/api/me/yakinlar'),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return veri as List<dynamic>;
  }

  Future<void> savePushToken(String pushToken) async {
    await _authorized(
      (token) => _http.post(
        _uri('/api/me/push-token'),
        headers: {..._jsonHeaders, 'Authorization': 'Bearer $token'},
        body: jsonEncode({'pushToken': pushToken}),
      ),
    );
  }

  Future<void> deletePushToken() async {
    await _authorized(
      (token) => _http.delete(
        _uri('/api/me/push-token'),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
  }

  /// Uygulama her açıldığında (soğuk başlangıç / arka plandan dönüş) bir kez
  /// çağrılır. `surum` opsiyonel — gönderilmezse eskisi gibi çalışır (200
  /// TAMAM), gönderilirse backend kullanıcının kurulu sürümünü günceller.
  Future<void> recordAppOpen({String? surum}) async {
    await _authorized(
      (token) => _http.post(
        _uri('/api/me/acilis'),
        headers: {
          'Authorization': 'Bearer $token',
          if (surum != null) ..._jsonHeaders,
        },
        body: surum != null ? jsonEncode({'surum': surum}) : null,
      ),
    );
  }

  /// İletişim tercihleri (ticari ileti — kampanya push/SMS/e-posta).
  /// Hizmet bildirimlerini (kupon, güvenlik, oturum) ETKİLEMEZ, onlar bu
  /// izne tabi değil.
  Future<Map<String, dynamic>> iletisimTercihleri() async {
    final veri = await _authorized(
      (token) => _http.get(
        _uri('/api/me/iletisim-tercihleri'),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return veri as Map<String, dynamic>;
  }

  /// Yalnızca gönderilen kanallar değişir; gönderilmeyenler aynen kalır.
  Future<Map<String, dynamic>> iletisimTercihleriniKaydet({
    required List<Map<String, dynamic>> tercihler,
    required String metinVersiyon,
  }) async {
    final veri = await _authorized(
      (token) => _http.put(
        _uri('/api/me/iletisim-tercihleri'),
        headers: {..._jsonHeaders, 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'tercihler': tercihler,
          'metinVersiyon': metinVersiyon,
        }),
      ),
    );
    return veri as Map<String, dynamic>;
  }

  Future<List<dynamic>> kvkkMetinleri() async {
    final veri = await _authorized(
      (token) => _http.get(
        _uri('/api/kvkk/metin'),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return veri as List<dynamic>;
  }

  Future<void> kvkkOnayGonder(List<Map<String, dynamic>> onaylar) async {
    await _authorized(
      (token) => _http.post(
        _uri('/api/kvkk/onay'),
        headers: {..._jsonHeaders, 'Authorization': 'Bearer $token'},
        body: jsonEncode({'onaylar': onaylar}),
      ),
    );
  }

  // ------------------------------------------------------- ilgi alanı & kampanya

  /// Sabit 13 kayıtlık ilgi alanı kataloğu — her kayıtta `secili` kullanıcının
  /// kendi seçimini taşır.
  Future<List<dynamic>> ilgiAlanlari() async {
    final veri = await _authorized(
      (token) => _http.get(
        _uri('/api/ilgi-alanlari'),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return veri as List<dynamic>;
  }

  Future<void> ilgiAlanlariniKaydet(List<int> ilgiAlaniIdleri) async {
    await _authorized(
      (token) => _http.put(
        _uri('/api/me/ilgi-alanlari'),
        headers: {..._jsonHeaders, 'Authorization': 'Bearer $token'},
        body: jsonEncode({'ilgiAlaniIdleri': ilgiAlaniIdleri}),
      ),
    );
  }

  /// Sayfalı kampanya listesi. `sayfaBoyutu` sunucuda en fazla 100.
  Future<Map<String, dynamic>> kampanyalar({
    int sayfa = 1,
    int sayfaBoyutu = 20,
    bool? sadeceIlgili,
    int? ilgiAlaniId,
  }) async {
    final veri = await _authorized(
      (token) => _http.get(
        _uri('/api/kampanyalar', {
          'sayfa': '$sayfa',
          'sayfaBoyutu': '$sayfaBoyutu',
          if (sadeceIlgili != null) 'sadeceIlgili': '$sadeceIlgili',
          if (ilgiAlaniId != null) 'ilgiAlaniId': '$ilgiAlaniId',
        }),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return veri as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> kampanyaDetay(String kampanyaGuid) async {
    final veri = await _authorized(
      (token) => _http.get(
        _uri('/api/kampanyalar/$kampanyaGuid'),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return veri as Map<String, dynamic>;
  }

  Future<void> kampanyaTiklama(String kampanyaGuid) async {
    await _authorized(
      (token) => _http.post(
        _uri('/api/kampanyalar/$kampanyaGuid/tiklama'),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
  }

  // --------------------------------------------------- kupon, puan, kan bağışı

  /// Kupon kodu üretir (ya da aynı kampanyadan daha önce alınmışsa aynısını
  /// döner — `KUPON_MEVCUT`). Hata kodları: `KUPON_YOK` (400),
  /// `KAMPANYA_BULUNAMADI` (404), `KOTA_DOLDU` (409), `YETERSIZ_PUAN`
  /// (409, `veri`: `bakiye`/`gereken`).
  Future<Map<String, dynamic>> kuponAl(String kampanyaGuid) async {
    final veri = await _authorized(
      (token) => _http.post(
        _uri('/api/kampanyalar/$kampanyaGuid/kupon'),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return veri as Map<String, dynamic>;
  }

  Future<List<dynamic>> kuponlarim() async {
    final veri = await _authorized(
      (token) => _http.get(
        _uri('/api/me/kuponlar'),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return veri as List<dynamic>;
  }

  Future<Map<String, dynamic>> puanBakiyem({
    int sayfa = 1,
    int sayfaBoyutu = 20,
  }) async {
    final veri = await _authorized(
      (token) => _http.get(
        _uri('/api/me/puan', {
          'sayfa': '$sayfa',
          'sayfaBoyutu': '$sayfaBoyutu',
        }),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return veri as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> kanGrubum() async {
    final veri = await _authorized(
      (token) => _http.get(
        _uri('/api/me/kan-grubu'),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return veri as Map<String, dynamic>?;
  }

  /// Silmek için `kanGrubu: null` gönderilir. Kan grubu özel nitelikli
  /// kişisel veri olduğundan kaydederken `acikRiza: true` zorunlu.
  Future<void> kanGrubuKaydet({required String? kanGrubu, bool acikRiza = true}) async {
    await _authorized(
      (token) => _http.put(
        _uri('/api/me/kan-grubu'),
        headers: {..._jsonHeaders, 'Authorization': 'Bearer $token'},
        body: jsonEncode({'kanGrubu': kanGrubu, 'acikRiza': acikRiza}),
      ),
    );
  }

  Future<Map<String, dynamic>> kanTalepleri({
    bool sadeceUygun = false,
    int sayfa = 1,
    int sayfaBoyutu = 20,
  }) async {
    final veri = await _authorized(
      (token) => _http.get(
        _uri('/api/kan-talepleri', {
          'sadeceUygun': '$sadeceUygun',
          'sayfa': '$sayfa',
          'sayfaBoyutu': '$sayfaBoyutu',
        }),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return veri as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> kanTalebiDetay(String kanTalebiGuid) async {
    final veri = await _authorized(
      (token) => _http.get(
        _uri('/api/kan-talepleri/$kanTalebiGuid'),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return veri as Map<String, dynamic>;
  }

  Future<void> kanBasvurusuYap(String kanTalebiGuid) async {
    await _authorized(
      (token) => _http.post(
        _uri('/api/kan-talepleri/$kanTalebiGuid/basvuru'),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
  }

  Future<void> kanBasvurusunuGeriCek(String kanTalebiGuid) async {
    await _authorized(
      (token) => _http.delete(
        _uri('/api/kan-talepleri/$kanTalebiGuid/basvuru'),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
  }

  Future<List<dynamic>> kanBagislarim() async {
    final veri = await _authorized(
      (token) => _http.get(
        _uri('/api/me/kan-bagislari'),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return veri as List<dynamic>;
  }
}

final birlikteApiClientProvider = Provider<BirlikteApiClient>((ref) {
  return BirlikteApiClient(
    BirlikteApiLoggingClient(http.Client()),
    ref.watch(secureStorageProvider),
    onSessionExpired: () => handleSessionExpired(ref),
  );
});
