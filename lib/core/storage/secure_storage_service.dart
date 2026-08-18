import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Token gibi hassas verilerin Keychain / EncryptedSharedPreferences üzerinde
/// tutulduğu katman.
class SecureStorageService {
  const SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';

  Future<String?> readAccessToken() => _storage.read(key: _kAccessToken);
  Future<String?> readRefreshToken() => _storage.read(key: _kRefreshToken);

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: _kAccessToken, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _kRefreshToken, value: refreshToken);
    }
  }

  Future<void> clear() => _storage.deleteAll();
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
