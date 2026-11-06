import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Token gibi hassas verilerin Keychain / EncryptedSharedPreferences üzerinde
/// tutulduğu katman.
///
/// birlikte-api'nin kendi oturum token'ları burada tutuluyor; Supabase'in
/// oturumunu `supabase_flutter` zaten kendi içinde güvenli şekilde saklıyor,
/// bu sınıfın ona ihtiyacı yok.
class SecureStorageService {
  const SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const _kAccessToken = 'birlikte_access_token';
  static const _kRefreshToken = 'birlikte_refresh_token';
  static const _kDeviceId = 'birlikte_device_id';

  Future<String?> readAccessToken() => _storage.read(key: _kAccessToken);
  Future<String?> readRefreshToken() => _storage.read(key: _kRefreshToken);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _kAccessToken, value: accessToken);
    await _storage.write(key: _kRefreshToken, value: refreshToken);
  }

  /// Oturumu kapatır — yalnızca birlikte-api token'larını siler, cihaz
  /// kimliğine dokunmaz (o kalıcı olmalı).
  Future<void> clearSession() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
  }

  /// Kalıcı cihaz kimliği (UUID). İlk girişte üretilip buraya yazılır;
  /// uygulama silinip yeniden kurulmadıkça aynı kalır.
  Future<String?> readDeviceId() => _storage.read(key: _kDeviceId);
  Future<void> saveDeviceId(String id) =>
      _storage.write(key: _kDeviceId, value: id);
}

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  // v11 varsayılanı zaten AES-GCM + RSA-OAEP anahtar sarmalama kullanıyor,
  // ayrıca bayrak gerekmiyor.
  return const SecureStorageService(
    FlutterSecureStorage(
      aOptions: AndroidOptions(storageNamespace: 'birlikte'),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  );
});
