import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../home/application/home_providers.dart';

/// Profil ekranındaki satır sayaçları (Figma: `profile` 3:1472 —
/// "Ailem 2/3", "Favori kampanyalar 8", "İlgi alanların 6 kategori").
class ProfileStats {
  const ProfileStats({
    required this.familyCount,
    required this.familyCapacity,
    required this.favoriteCount,
    required this.interestCount,
  });

  final int familyCount;
  final int familyCapacity;
  final int favoriteCount;
  final int interestCount;
}

class ProfileStatsRepository {
  const ProfileStatsRepository(this._client);

  final SupabaseClient _client;

  /// RLS zaten oturum sahibinin satırlarıyla sınırlıyor; ayrıca filtre yok.
  ///
  /// `count: exact, head: true` ile satırlar çekilmiyor, yalnızca sayı
  /// dönüyor — profil ekranı listelerin kendisini göstermiyor.
  Future<({int family, int interests})> fetch() async {
    final family = await _client
        .from('family_members')
        .count(CountOption.exact);
    final interests = await _client
        .from('profile_interests')
        .count(CountOption.exact);
    return (family: family, interests: interests);
  }
}

final profileStatsRepositoryProvider = Provider<ProfileStatsRepository>(
  (ref) => ProfileStatsRepository(ref.watch(supabaseProvider)),
);

final profileStatsProvider = FutureProvider<ProfileStats>((ref) async {
  ref.watch(authStateProvider);

  final counts = await ref.watch(profileStatsRepositoryProvider).fetch();
  return ProfileStats(
    familyCount: counts.family,
    familyCapacity: ref.watch(familyCapacityProvider),
    // Favoriler zaten bellekte tutuluyor; ayrı sorgu atmaya gerek yok.
    favoriteCount: ref.watch(favoriteSlugsProvider).length,
    interestCount: counts.interests,
  );
});
