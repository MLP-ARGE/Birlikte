/// Ortam ayarları.
enum Flavor { dev, staging, prod }

abstract final class AppConfig {
  static const String appName = 'Birlikte';

  static const Flavor flavor = Flavor.dev;

  /// Supabase proje URL'i.
  ///
  /// `--dart-define=SUPABASE_URL=https://xxx.supabase.co` ile geçilir;
  /// varsayılan dev projesidir.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://iahzmjzigmmbxcivhhtr.supabase.co',
  );

  /// Supabase anon anahtarı.
  ///
  /// Bu değer GİZLİ DEĞİLDİR — tasarımı gereği istemciye gömülür ve
  /// uygulama binary'sinden çıkarılabilir. Güvenliği Row Level Security
  /// sağlar, anahtarın gizliliği değil. service_role anahtarı ise asla
  /// istemciye konmaz (yalnızca Edge Function'larda).
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
        'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlhaHptanppZ21tYnhjaXZoaHRyIiwicm9s'
        'ZSI6ImFub24iLCJpYXQiOjE3ODgyMzQxMDQsImV4cCI6MjEwMzgxMDEwNH0.'
        'Ol9at1LHriEmv0xGP6Qk6STe-7IwKU9r7PRYZO79UzQ',
  );

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static bool get isProd => flavor == Flavor.prod;
}
