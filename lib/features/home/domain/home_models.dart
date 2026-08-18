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
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
}

/// Kampanya kartı (Figma: `Card / Campaign` 149:540).
class Campaign {
  const Campaign({
    required this.brand,
    required this.title,
    required this.discountLabel,
    required this.daysLeft,
    this.institution,
    this.pointsCost,
    this.imageUrl,
    this.favorite = false,
  });

  final String brand;
  final String title;

  /// Örn. "%25" — tasarımda vurgulu marka renginde.
  final String discountLabel;
  final int daysLeft;

  /// null ise kampanya tüm kurumlara açık.
  final Institution? institution;

  /// Kampanyanın puan karşılığı; null ise puan etiketi gösterilmez.
  final int? pointsCost;
  final String? imageUrl;
  final bool favorite;
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
