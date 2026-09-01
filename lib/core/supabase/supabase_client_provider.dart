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

/// Oturum açık mı — router korumasının kullandığı kontrol.
///
/// Değer değil, **fonksiyon** döndürüyor. Sebebi ince ama kritik:
/// `Provider<bool>` değeri önbelleğe alır ve yalnızca bağımlılığı
/// (`authStateProvider` stream'i) yeni olay yayınlayınca tazelenir. Oysa
/// `setSession()` döner dönmez `currentSession` doluyor ama stream olayı
/// henüz yayılmamış oluyor. Koruma o anda önbellekteki eski `false`
/// değerini görüp kullanıcıyı login'e geri atıyordu — kod girildikten
/// sonra ekran başa dönüyordu.
///
/// Fonksiyonun kendisi önbelleklenir, ama her çağrıldığında oturumu
/// istemciden taze okur. Testler bunu değiştirebiliyor.
final sessionCheckProvider = Provider<bool Function()>((ref) {
  final client = ref.watch(supabaseProvider);
  return () => client.auth.currentSession != null;
});

/// Oturum açık mı (widget'ların izlemesi için reaktif hâl).
final isLoggedInProvider = Provider<bool>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(sessionCheckProvider)();
});

/// Oturum açmış kullanıcının kimliği; yoksa null.
final currentUserIdProvider = Provider<String?>((ref) {
  // Oturum değiştikçe yeniden hesaplansın.
  ref.watch(authStateProvider);
  return ref.watch(supabaseProvider).auth.currentUser?.id;
});
