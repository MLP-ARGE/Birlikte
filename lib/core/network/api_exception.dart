import 'package:dio/dio.dart';

/// Ağ hatalarının kullanıcıya gösterilebilir tek tipe indirgenmiş hâli.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  /// Dio hatasını kullanıcıya gösterilebilir Türkçe mesaja çevirir.
  factory ApiException.fromDio(DioException e) {
    final status = e.response?.statusCode;

    final message = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout =>
        'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.',
      DioExceptionType.connectionError =>
        'İnternet bağlantısı kurulamadı. Bağlantınızı kontrol edin.',
      DioExceptionType.badCertificate =>
        'Güvenli bağlantı kurulamadı.',
      DioExceptionType.cancel => 'İstek iptal edildi.',
      DioExceptionType.badResponse => switch (status) {
          400 => 'Geçersiz istek.',
          401 => 'Oturumunuzun süresi doldu. Lütfen tekrar giriş yapın.',
          403 => 'Bu işlem için yetkiniz bulunmuyor.',
          404 => 'Kayıt bulunamadı.',
          422 => 'Gönderilen bilgiler doğrulanamadı.',
          429 => 'Çok fazla istek gönderildi. Lütfen bekleyin.',
          _ when status != null && status >= 500 =>
            'Sunucuya şu anda ulaşılamıyor. Lütfen daha sonra deneyin.',
          _ => 'Beklenmeyen bir hata oluştu.',
        },
      DioExceptionType.unknown => 'Beklenmeyen bir hata oluştu.',
    };

    return ApiException(message, statusCode: status, cause: e);
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
