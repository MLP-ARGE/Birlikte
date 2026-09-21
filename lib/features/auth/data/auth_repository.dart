import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/device/device_info_provider.dart';
import '../../../core/supabase/supabase_client_provider.dart';

/// Giriş akışının hataları — ekranın kullanıcıya ne göstereceğini belirler.
enum AuthFailure {
  /// Kullanıcı adı ya da parola hatalı.
  invalidCredentials,

  /// SMS kodu yanlış veya süresi dolmuş.
  invalidCode,

  /// Giriş denemesinin süresi doldu; baştan başlamak gerekiyor.
  challengeExpired,

  /// Çalışanın şubesi henüz bir kuruma eşlenmemiş — bizim tamamlamamız
  /// gereken bir veri eksiği, kullanıcının yapabileceği bir şey yok.
  branchNotMapped,

  /// Ağ veya sunucu hatası.
  network,
}

class AuthException implements Exception {
  const AuthException(this.failure, [this.message]);

  final AuthFailure failure;
  final String? message;

  @override
  String toString() => 'AuthException($failure, $message)';
}

/// Parola doğrulandı, SMS gönderildi. İkinci adım bu kimlikle sürüyor.
class OtpChallenge {
  const OtpChallenge({required this.challengeId, this.maskedPhone});

  /// Sunucudaki giriş denemesinin kimliği.
  ///
  /// PDKS token'ının yerine geçiyor: token cihaza hiç inmiyor, sunucuda
  /// tutuluyor. Böylece istemci SMS adımını atlayıp doğrudan PDKS'ye
  /// istek atamıyor.
  final String challengeId;

  /// PDKS'den gelen maskeli numara, örn. "54******89". Vermezse null.
  final String? maskedPhone;
}

/// Giriş akışı — MLPCARE PDKS üzerinden.
///
/// Kullanıcı adı + parola PDKS'de doğrulanır, ardından SMS kodu onaylanır.
/// Her iki adım da Edge Function üzerinden geçer: parola ve PDKS token'ı
/// cihazda tutulmaz.
///
/// PDKS kimliği doğrular, Supabase yetkilendirmeyi taşır — kampanya, kupon,
/// puan ve favori verileri RLS ile auth.uid() üzerinden korunduğu için
/// doğrulama sonunda bir Supabase oturumu kuruluyor.
class AuthRepository {
  const AuthRepository(this._client, this._device);

  final SupabaseClient _client;
  final PdksDeviceInfo? _device;

  /// Adım 1: kullanıcı adı + parola. Başarılıysa PDKS SMS gönderir.
  Future<OtpChallenge> requestOtp({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'pdks-login',
        body: {
          'username': username,
          'password': password,
          if (_device != null) 'device': _device.toJson(),
        },
      );

      final data = response.data as Map<String, dynamic>?;
      if (response.status != 200 || data == null) {
        throw AuthException(_failureFor(response.status, data));
      }

      return OtpChallenge(
        challengeId: data['challenge_id'] as String,
        maskedPhone: data['masked_phone'] as String?,
      );
    } on AuthException {
      rethrow;
    } on FunctionException catch (e) {
      throw AuthException(_failureFor(e.status, e.details));
    } catch (e) {
      throw AuthException(AuthFailure.network, e.toString());
    }
  }

  /// Adım 2: SMS kodunu doğrula, oturumu aç.
  Future<void> verifyOtp({
    required String challengeId,
    required String code,
  }) async {
    late final Map<String, dynamic> data;
    try {
      final response = await _client.functions.invoke(
        'pdks-verify',
        body: {
          'challenge_id': challengeId,
          'code': code,
          if (_device != null) 'device': _device.toJson(),
        },
      );
      if (response.status != 200 || response.data == null) {
        throw AuthException(
          _failureFor(response.status, response.data as Map<String, dynamic>?),
        );
      }
      data = Map<String, dynamic>.from(response.data as Map);
    } on AuthException {
      rethrow;
    } on FunctionException catch (e) {
      throw AuthException(_failureFor(e.status, e.details));
    } catch (e) {
      throw AuthException(AuthFailure.network, e.toString());
    }

    // Edge Function oturumu döndürüyor; istemci tarafına kuruyoruz ki
    // sonraki tüm istekler kullanıcı JWT'siyle (ve RLS altında) gitsin.
    final session = data['session'] as Map<String, dynamic>?;
    final refreshToken = session?['refresh_token'] as String?;
    if (refreshToken == null) {
      throw const AuthException(AuthFailure.network, 'oturum alınamadı');
    }

    await _client.auth.setSession(refreshToken);
  }

  /// Sunucunun döndürdüğü hata kodunu ekranın anlayacağı türe çevirir.
  static AuthFailure _failureFor(int? status, Object? body) {
    final code = body is Map ? body['error'] as String? : null;
    return switch (code) {
      'invalid_credentials' => AuthFailure.invalidCredentials,
      'invalid_code' => AuthFailure.invalidCode,
      'challenge_expired' => AuthFailure.challengeExpired,
      'branch_not_mapped' => AuthFailure.branchNotMapped,
      _ => status == 401 ? AuthFailure.invalidCode : AuthFailure.network,
    };
  }

  Future<void> signOut() => _client.auth.signOut();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Cihaz bilgisi henüz yüklenmediyse null geçiyoruz: giriş bunu beklemek
  // zorunda değil, Edge Function eksik alanlar için nötr değerlere düşüyor.
  final device = ref.watch(deviceInfoProvider).value;
  return AuthRepository(ref.watch(supabaseProvider), device);
});
