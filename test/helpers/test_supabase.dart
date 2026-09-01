import 'package:supabase_flutter/supabase_flutter.dart';

/// PKCE doğrulayıcısını bellekte tutan depo.
///
/// Supabase, `persistSession: false` olsa bile `pkceAsyncStorage` için
/// varsayılan olarak SharedPreferences kuruyor; test ortamında platform
/// kanalı olmadığından bu `MissingPluginException` atıyor. Bellek içi
/// uygulama sorunu kökten çözüyor.
class _InMemoryPkceStorage extends GotrueAsyncStorage {
  final _values = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => _values[key];

  @override
  Future<void> setItem({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    _values.remove(key);
  }
}

/// Testler için Supabase'i başlatır.
///
/// Gerçek bir sunucuya bağlanmaz: URL yerel ve erişilemez. Veri sağlayan
/// provider'lar testlerde sahte repository ile değiştiriliyor (bkz.
/// `fakes.dart`), bu yüzden ağ isteği çıkmıyor.
Future<void> initSupabaseForTests() async {
  if (_initialized) return;
  await Supabase.initialize(
    url: 'http://localhost:54321',
    publishableKey: 'test-anon-key',
    authOptions: FlutterAuthClientOptions(
      autoRefreshToken: false,
      persistSession: false,
      detectSessionInUri: false,
      pkceAsyncStorage: _InMemoryPkceStorage(),
    ),
    debug: false,
  );
  _initialized = true;
}

bool _initialized = false;
