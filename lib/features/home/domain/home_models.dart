import '../../../core/theme/app_institutions.dart';

/// Puan özeti (Figma: `points-card` 201:173).
class PointsSummary {
  const PointsSummary({
    required this.total,
    required this.usable,
    required this.pending,
  });

  final int total;
  final int usable;
  final int pending;
}

/// "Sana Özel" karusel kartı (Figma: `promo-card` 201:204).
class PromoOffer {
  const PromoOffer({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.campaignId,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;

  /// Doluysa "İncele" dokunuşu bu kampanyanın detayına gider.
  final String? campaignId;
}

/// Kampanya kategorisi (Figma: `Chip / Category` — `chips-row` 445:10135).
enum CampaignCategory {
  foodDrink('Yeme & İçme'),
  shopping('Alışveriş'),
  health('Sağlık'),
  education('Eğitim'),
  automotive('Otomotiv'),
  travel('Seyahat'),
  fuel('Akaryakıt'),
  pets('Evcil Hayvan');

  const CampaignCategory(this.label);

  final String label;
}

/// Kampanyanın geçerli olduğu şube/kampüs (Figma: `branch-card`,
/// `campaign-branches` 398:9110).
class CampaignBranch {
  const CampaignBranch({
    required this.name,
    required this.distanceLabel,
    required this.address,
    required this.hours,
  });

  final String name;

  /// Örn. "4,2 km".
  final String distanceLabel;
  final String address;

  /// Örn. "Hafta içi 09:00 – 18:00".
  final String hours;
}

/// Kampanya kartı ve detayı (Figma: `Card / Campaign` 149:540,
/// `campaign-detail` 3:686).
///
/// Liste kartı yalnızca [brand], [title], [discountLabel], [daysLeft]
/// gerektirir; detay ekranındaki alanlar (`description`, `tags`, `steps`...)
/// isteğe bağlıdır — bir kampanyanın tam editoryal içeriği olmayabilir,
/// o durumda detay ekranı ilgili bölümü gizler.
class Campaign {
  const Campaign({
    required this.id,
    required this.brand,
    required this.title,
    required this.discountLabel,
    required this.daysLeft,
    required this.category,
    this.institution,
    this.pointsCost,
    this.imageUrl,
    this.favorite = false,
    this.brandType,
    this.description,
    this.validity,
    this.tags = const [],
    this.steps = const [],
    this.whoQualifies = const [],
    this.rules = const [],
    this.cancellationNote,
    this.branches = const [],
  });

  /// Kampanya kimliği — favori durumu ve detay yönlendirmesi bu anahtarla
  /// çalışır.
  final String id;
  final String brand;
  final String title;

  /// Örn. "%25", "150 TL", "Ücretsiz" — biçimi markaya göre değişir, düz
  /// metin olarak gösterilir.
  final String discountLabel;
  final int daysLeft;
  final CampaignCategory category;

  /// null ise kampanya tüm kurumlara açık.
  final Institution? institution;

  /// Kampanyanın puan karşılığı; null ise puan etiketi gösterilmez.
  final int? pointsCost;
  final String? imageUrl;

  /// Seed veride varsayılan durum; gerçek zamanlı durum için favori
  /// provider'ına bakılmalı (bkz. `favoriteCampaignIdsProvider`).
  final bool favorite;

  /// Detay ekranı marka satırının alt metni, örn. "Eğitim Kurumu".
  final String? brandType;
  final String? description;

  /// Örn. "1 Eylül 2026 — 31 Ocak 2027".
  final String? validity;
  final List<String> tags;

  /// "Nasıl kullanılır?" adımları.
  final List<String> steps;

  /// "Kimler yararlanabilir?" listesi.
  final List<String> whoQualifies;

  /// "Kampanya koşulları" listesi.
  final List<String> rules;
  final String? cancellationNote;
  final List<CampaignBranch> branches;

  /// Detay ekranında "Koşullar" sekmesini göstermeye yeten içerik var mı.
  bool get hasTermsDetail =>
      whoQualifies.isNotEmpty || rules.isNotEmpty || cancellationNote != null;
}

/// Kan bağışı talebi (Figma: `request-row` 205:437).
class BloodRequest {
  const BloodRequest({
    required this.name,
    required this.bloodType,
    required this.hospital,
    this.urgent = false,
  });

  final String name;

  /// Örn. "A Rh−".
  final String bloodType;
  final String hospital;
  final bool urgent;
}

/// Aile üyesi (Figma: `member-row` 205:474).
class FamilyMember {
  const FamilyMember({required this.name, required this.relation});

  final String name;

  /// Örn. "Eş", "Çocuk".
  final String relation;

  /// Avatar baş harfleri — "Emre Yılmaz" → "EY".
  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((w) => w.substring(0, 1).toUpperCase())
      .join();
}
