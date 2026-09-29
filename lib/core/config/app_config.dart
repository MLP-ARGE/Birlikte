/// Ortam ayarları.
enum Flavor { dev, staging, prod }

abstract final class AppConfig {
  static const String appName = 'MLPCARE Birlikte';

  /// Sürüm burada TUTULMUYOR. Elle yazıldığı sürece pubspec'ten kaçınılmaz
  /// olarak kayıyordu: uygulama 1.0.0 iken profil ekranı "v2.4.1" gösteriyordu.
  /// Gerçek değer çalışma anında paket üst verisinden okunuyor —
  /// bkz. [appVersionProvider].
  static const String buildYear = '2026';

  /// Yasal ve destek bağlantıları.
  ///
  /// Boş bırakılanlar profil ekranında GÖSTERİLMEZ. Hiçbir şey yapmayan bir
  /// satır koymaktansa satırı hiç göstermemek doğru: Apple'ın 2.1 kuralı
  /// çalışmayan öğeleri eksiklik sayıyor.
  ///
  /// Gizlilik politikası App Store Connect'te de ZORUNLU bir alan; oraya
  /// yazılacak adresle burası aynı olmalı.
  static const String privacyPolicyUrl = '';
  static const String termsUrl = '';
  static const String supportUrl = '';

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
