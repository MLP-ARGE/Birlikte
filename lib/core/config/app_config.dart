/// Ortam ayarları.
///
/// Gerçek base URL'ler backend ekibinden alınıp `--dart-define` ile
/// geçilecek; buradaki değerler yalnızca yer tutucudur.
enum Flavor { dev, staging, prod }

abstract final class AppConfig {
  static const String appName = 'Birlikte';

  static const Flavor flavor = Flavor.dev;

  /// `flutter run --dart-define=API_BASE_URL=https://...`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://example.invalid/api',
  );

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static bool get isProd => flavor == Flavor.prod;
}
