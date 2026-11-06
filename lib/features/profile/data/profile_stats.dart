import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/verified_profile_provider.dart';
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

/// Tüm sayaçlar artık zaten yüklenmiş başka provider'lardan türetiliyor
/// (aile: birlikte-api yakınlar, favoriler: cihaz-yerel, ilgi alanı: profil);
/// ayrı bir Supabase sorgusuna gerek kalmadı.
final profileStatsProvider = FutureProvider<ProfileStats>((ref) async {
  final profile = ref.watch(verifiedProfileProvider);
  return ProfileStats(
    familyCount: ref.watch(familyMembersProvider).length,
    familyCapacity: ref.watch(familyCapacityProvider),
    favoriteCount: ref.watch(favoriteSlugsProvider).length,
    interestCount: profile.interestCount,
  );
});
