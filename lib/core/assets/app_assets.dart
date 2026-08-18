/// Asset yolları tek yerde — dizgi hatası derleme zamanında değil, burada biter.
///
/// Görseller Figma'dan @3x PNG olarak alındı (dosya key `hYohg2W2qUOunLDE2TIPzE`).
abstract final class AppAssets {
  static const _brands = 'assets/images/brands';
  static const _onboarding = 'assets/images/onboarding';

  /// Kurum logo kartları — arka plan rengi ve radius'u (14) görselin içinde.
  /// Figma: `logo-card-*` 166x116.
  static const brandLivKoleji = '$_brands/liv-koleji.png';
  static const brandMedicalPark = '$_brands/medical-park.png';
  static const brandIstinyeUniversitesi = '$_brands/istinye-universitesi.png';
  static const brandLivHospital = '$_brands/liv-hospital.png';

  /// MLPCARE Birlikte logosu — Figma `LOGO` 111x44, @4x.
  static const logoBirlikte = 'assets/images/logo-birlikte.png';

  /// Onboarding illüstrasyonları — Figma: `illustration` 342x300.
  static const onboardingCampaigns = '$_onboarding/campaigns.png';
  static const onboardingCoupons = '$_onboarding/slide-3.png';
}
