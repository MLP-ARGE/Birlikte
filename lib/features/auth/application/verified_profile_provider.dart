import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_institutions.dart';
import '../domain/verified_profile.dart';

/// Doğrulanmış kullanıcı profili.
///
/// TODO(api): SMS doğrulaması sonrası kurum eşleştirme ucundan gelecek. Şimdilik
/// Figma'daki örnek kayıt — ekranlar gerçek veriyle aynı şekilde çalışıyor,
/// yalnızca bu provider'ın gövdesi değişecek.
final verifiedProfileProvider = Provider<VerifiedProfile>(
  (ref) => VerifiedProfile(
    fullName: 'Ayşe Yılmaz',
    institution: Institution.medicalPark,
    region: 'İstanbul Bölge',
    department: 'Bilgi Teknolojileri',
    facility: 'Göztepe Hastanesi',
    employeeNo: 'MP-984302',
    matchedAt: DateTime(2026, 7, 8),
  ),
);
