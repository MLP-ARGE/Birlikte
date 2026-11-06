import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_storage_service.dart';

/// Oturum durumu — router koruması ve ekranlar bunu izliyor.
///
/// Supabase'in `onAuthStateChange`'inin yerini alıyor: artık Supabase hiç
/// kullanılmıyor (bkz. [BirlikteAuthRepository] dokümantasyonu), oturumun
/// TEK kaynağı birlikte-api'nin SecureStorage'daki token'ları.
///
/// Notifier olmasının sebebi: `refreshToken` okumak asenkron (Keychain),
/// ama router'ın yönlendirme kararı senkron bir `bool` istiyor. Başlangıçta
/// `_loadInitial()` ile bir kez asenkron okunuyor; sonrasında giriş/çıkış
/// anında `set()` ile senkron güncelleniyor — login akışı zaten token'ı
/// yazdığı an burayı da güncelliyor, ayrıca okumaya gerek yok.
class BirlikteSessionNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadInitial();
    return false;
  }

  Future<void> _loadInitial() async {
    final token = await ref.read(secureStorageProvider).readRefreshToken();
    state = token != null;
  }

  void set({required bool value}) => state = value;
}

final birlikteSessionProvider =
    NotifierProvider<BirlikteSessionNotifier, bool>(
      BirlikteSessionNotifier.new,
    );
