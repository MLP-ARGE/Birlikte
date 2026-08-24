/// Rota yolları tek yerde (Figma prototip akışı: 0:1 sayfası, başlangıç 3:12).
abstract final class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const smsVerification = '/sms-verification';
  static const verificationError = '/verification-error';
  static const institutionMatch = '/institution-match';
  static const welcome = '/welcome';
  static const interestSelection = '/interest-selection';
  static const home = '/home';

  // Alt navigasyon sekmeleri (Figma: `bottom-nav` 148:389).
  static const campaigns = '/kampanyalar';
  static const wallet = '/cuzdanim';
  static const kandas = '/kandas';
  static const profile = '/profil';

  /// Kampanya detayı — kök seviyede, alt navigasyonun dışında (Figma:
  /// `campaign-detail` 3:686'da bottom-nav yok, CTA bar en altta).
  static const campaignDetailSegment = '$campaigns/kampanya/:id';
  static String campaignDetail(String id) => '$campaigns/kampanya/$id';
}
