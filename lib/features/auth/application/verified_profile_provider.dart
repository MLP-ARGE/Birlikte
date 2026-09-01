import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_institutions.dart';
import '../data/profile_repository.dart';
import '../domain/verified_profile.dart';

/// Doğrulanmış kullanıcı profili.
///
/// Supabase'den gelir; oturum yoksa ya da henüz yüklenmediyse aşağıdaki
/// yer tutucu döner. Ekranlar senkron bir profil beklediği için bu
/// provider `AsyncValue` yerine düz değer veriyor — asıl kaynak
/// [profileProvider], burası onun senkron görünümü.
final verifiedProfileProvider = Provider<VerifiedProfile>((ref) {
  return ref.watch(profileProvider).value ?? _placeholder;
});

/// Profil yüklenene kadar gösterilen boş kayıt. Gerçek veri gelince
/// ekranlar kendiliğinden yenilenir.
final _placeholder = VerifiedProfile(
  fullName: '',
  institution: Institution.medicalPark,
  region: '',
  department: '',
  facility: '',
  employeeNo: '',
  matchedAt: DateTime(2026),
);
