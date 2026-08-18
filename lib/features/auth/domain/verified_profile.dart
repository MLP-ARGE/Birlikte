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
  final String employeeNo;

  /// Kurum kaydının eşleştiği tarih.
  final DateTime matchedAt;

  /// Profil fotoğrafı; yoksa avatar baş harflere düşer.
  final String? photoUrl;

  /// Karşılama başlığında kullanılan ad ("Hoş geldin, Ayşe").
  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  /// identity-card alt satırı — Figma'da nokta ayraçlı.
  String get placement => '$region • $department';
}
