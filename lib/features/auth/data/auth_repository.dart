import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';

/// Giriş akışının hataları — ekranın kullanıcıya ne göstereceğini belirler.
enum AuthFailure {
  /// Girilen numara/TCKN biçimsel olarak geçersiz.
  invalidIdentifier,

  /// Kod yanlış veya süresi dolmuş.
  invalidCode,

  /// Çok fazla deneme yapıldı.
  rateLimited,

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

/// Kod gönderiminin sonucu.
class OtpChallenge {
  const OtpChallenge({required this.maskedPhone});

  /// Kodun gittiği numaranın maskeli hâli, örn. "+90 532 *** ** 48".
  ///
  /// null olabilir: bordroda eşleşme bulunmadığında sunucu bilerek aynı
  /// yanıtı döner (çalışan listesi numara denenerek çıkarılamasın diye).
  /// Bu durumda SMS ekranı yine açılır ama kod gelmez.
  final String? maskedPhone;
}

/// Giriş akışı (Figma: login → sms-verification).
///
/// Bordro doğrulaması ve profil bağlama sunucuda (Edge Function) yapılır;
/// istemci yalnızca iki uç çağırır.
class AuthRepository {
  const AuthRepository(this._client);

  final SupabaseClient _client;

  /// Telefon veya TCKN ile kod ister.
  Future<OtpChallenge> requestOtp(String identifier) async {
    try {
      final response = await _client.functions.invoke(
        'auth-lookup',
        body: {'identifier': identifier},
      );

      final data = response.data as Map<String, dynamic>?;
      if (response.status == 429) {
        throw const AuthException(AuthFailure.rateLimited);
      }
      if (response.status != 200 || data == null) {
        throw const AuthException(AuthFailure.network);
      }

      return OtpChallenge(maskedPhone: data['masked_phone'] as String?);
    } on AuthException {
      rethrow;
    } on FunctionException catch (e) {
      if (e.status == 429) {
        throw const AuthException(AuthFailure.rateLimited);
      }
      if (e.status == 400) {
        throw const AuthException(AuthFailure.invalidIdentifier);
      }
      throw AuthException(AuthFailure.network, e.toString());
    } catch (e) {
      throw AuthException(AuthFailure.network, e.toString());
    }
  }

  /// Kodu doğrular, oturumu açar ve profili bordroya bağlar.
  Future<void> verifyOtp({
    required String identifier,
    required String code,
  }) async {
    late final Map<String, dynamic> data;
    try {
      final response = await _client.functions.invoke(
        'auth-verify',
        body: {'identifier': identifier, 'code': code},
      );
      if (response.status == 401) {
        throw const AuthException(AuthFailure.invalidCode);
      }
      if (response.status != 200 || response.data == null) {
        throw const AuthException(AuthFailure.network);
      }
      data = Map<String, dynamic>.from(response.data as Map);
    } on AuthException {
      rethrow;
    } on FunctionException catch (e) {
      throw AuthException(
        e.status == 401 ? AuthFailure.invalidCode : AuthFailure.network,
      );
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

  Future<void> signOut() => _client.auth.signOut();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseProvider)),
);
