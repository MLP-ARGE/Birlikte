import 'package:flutter/widgets.dart';

import '../assets/app_assets.dart';

/// MLPCARE çatısındaki kurumlar (Figma: onboarding logo kartları, Institution
/// badge, kampanya ve kupon ekranlarında marka filtreleri).
///
/// Renkler kurumların kendi marka renkleri — [AppColors] palet ölçeğinin
/// parçası değil, o yüzden burada duruyor.
enum Institution {
  medicalPark(
    label: 'Medical Park',
    color: Color(0xFFE31F24),
    logo: AppAssets.brandMedicalPark,
  ),
  livHospital(
    label: 'Liv Hospital',
    color: Color(0xFF008FC5),
    logo: AppAssets.brandLivHospital,
  ),
  livKoleji(
    label: 'Liv Koleji',
    color: Color(0xFF008FC5),
    logo: AppAssets.brandLivKoleji,
  ),
  istinyeUniversitesi(
    label: 'İstinye Üniversitesi',
    color: Color(0xFF1C3B5C),
    logo: AppAssets.brandIstinyeUniversitesi,
  );

  const Institution({
    required this.label,
    required this.color,
    required this.logo,
  });

  /// Kullanıcıya gösterilen ad.
  final String label;

  /// Kurumun marka rengi — badge şeridi, filtre vurgusu.
  final Color color;

  /// Logo kartı (arka plan rengi görselin içinde).
  final String logo;

  /// Logo döşemesindeki baş harfler (Figma: `logo-tile` "MP").
  /// "Medical Park" → "MP", "İstinye Üniversitesi" → "İÜ".
  String get initials => label
      .split(RegExp(r'\s+'))
      .take(2)
      .map((w) => w.characters.first.toUpperCase())
      .join();
}
