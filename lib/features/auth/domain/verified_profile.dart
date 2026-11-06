import '../../../core/theme/app_institutions.dart';

/// Kurum doğrulaması geçmiş kullanıcı (Figma: `welcome-screen` identity-card,
/// `institution-match`).
class VerifiedProfile {
  const VerifiedProfile({
    required this.fullName,
    required this.institution,
    required this.region,
    required this.department,
    required this.facility,
    required this.employeeNo,
    required this.matchedAt,
    this.photoUrl,
    this.position,
    this.email,
    this.managerName,
    this.personType,
    this.hiredAt,
    this.language = 'tr',
    this.theme = 'system',
    this.interestCount = 0,
    this.missingInfo = const [],
  });

  final String fullName;
  final Institution institution;

  /// Örn. "İstanbul Bölge".
  final String region;

  /// Örn. "Bilgi Teknolojileri".
  final String department;

  /// Çalıştığı tesis, örn. "Göztepe Hastanesi".
  final String facility;

  /// Bordro kayıtlarındaki çalışan numarası, örn. "MP-984302".
  /// PDKS entegrasyonu için sicil numarası. birlikte-api karşılığı yok.
  final String? employeeNo;

  /// Kurum kaydının eşleştiği tarih.
  final DateTime matchedAt;

  /// Profil fotoğrafı; yoksa avatar baş harflere düşer.
  ///
  /// PDKS fotoğrafı base64 olarak veriyor; Edge Function onu özel bir
  /// Storage bucket'ına yazıyor ve burada imzalı URL'i tutuluyor.
  final String? photoUrl;

  /// PDKS'den gelen görev/unvan, örn. "Mobil Uygulama Geliştirme Sorumlusu".
  final String? position;

  /// Kurum e-postası.
  final String? email;

  /// Bağlı olduğu yöneticinin adı.
  final String? managerName;

  /// PDKS'deki kişi tipi, örn. "Çalışan".
  final String? personType;

  /// İşe giriş tarihi.
  final DateTime? hiredAt;

  /// `public.app_language` — 'tr' | 'en'.
  final String language;

  /// `public.app_theme` — 'system' | 'light' | 'dark'.
  final String theme;

  /// Oturum sahibinin seçtiği ilgi alanı sayısı (profil ekranındaki sayaç).
  final int interestCount;

  /// `/api/me`'nin `eksikBilgiler` listesi: `"CINSIYET"`, `"AD"`, `"SOYAD"`
  /// olabilir. Giriş engellemez (yalnızca doğum tarihi/telefon engeller),
  /// bu üçü giriş yapıldıktan sonra tamamlanır/bildirilir.
  final List<String> missingInfo;

  /// Kullanıcının kendisinin tamamlayabileceği tek alan — diğer ikisi (ad,
  /// soyad) kurum kaydından düzeltilir, uygulamadan değiştirilemez.
  bool get genderMissing => missingInfo.contains('CINSIYET');

  /// Ad ve/veya soyad kurumda eksik — kullanıcı bunu uygulamadan
  /// düzeltemez, yalnızca bilgilendirilir.
  bool get nameMissingAtInstitution =>
      missingInfo.contains('AD') || missingInfo.contains('SOYAD');

  /// Karşılama başlığında kullanılan ad ("Hoş geldin, Ayşe").
  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  /// identity-card alt satırı — Figma'da nokta ayraçlı.
  ///
  /// PDKS bölge bilgisi vermiyor; boşsa ayraç bırakmadan yalnızca departman
  /// gösteriliyor ("• Bilgi Teknolojileri" gibi sarkık bir metin olmasın).
  String get placement =>
      [region, department].where((p) => p.isNotEmpty).join(' • ');
}
