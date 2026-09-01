import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Uygulama genelindeki tek Supabase istemcisi.
///
/// `Supabase.initialize` main.dart'ta bir kez çağrılır; bu provider yalnızca
/// hazır istemciyi verir.
final supabaseProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// Oturum durumu. Router bunu izleyerek giriş/çıkışta yönlendirme yapar.
final authStateProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(supabaseProvider).auth.onAuthStateChange,
);

/// Oturum açık mı.
///
/// Router'ın koruması bunu okuyor. Ayrı bir provider olmasının sebebi
/// test edilebilirlik: testler gerçek bir Supabase oturumu kurmak yerine
/// bunu değiştirebiliyor.
final isLoggedInProvider = Provider<bool>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(supabaseProvider).auth.currentSession != null;
});

/// Oturum açmış kullanıcının kimliği; yoksa null.
final currentUserIdProvider = Provider<String?>((ref) {
  // Oturum değiştikçe yeniden hesaplansın.
  ref.watch(authStateProvider);
  return ref.watch(supabaseProvider).auth.currentUser?.id;
});
