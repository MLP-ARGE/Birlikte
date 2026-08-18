/// Boşluk ölçeği (Figma: 02 — Foundations / Spacing & Radius).
/// 4dp tabanlı. Ekran kenar boşluğu 24, kart iç boşluğu 16, bölümler arası 32.
abstract final class AppSpacing {
  static const double s1 = 2;
  static const double s2 = 4;
  static const double s3 = 8;
  static const double s4 = 12;
  static const double s5 = 16;
  static const double s6 = 20;
  static const double s7 = 24;
  static const double s8 = 32;
  static const double s9 = 40;
  static const double s10 = 48;
  static const double s11 = 64;
  static const double s12 = 80;

  /// Ekranların standart yatay kenar boşluğu.
  static const double screenH = s7; // 24
  /// Kart iç boşluğu.
  static const double cardPad = s5; // 16
  /// Bölümler arası dikey boşluk.
  static const double sectionGap = s8; // 32
}

/// Köşe yarıçapları (Figma: radius.*).
abstract final class AppRadius {
  /// Rozet
  static const double xs = 4;
  /// Chip · Input
  static const double sm = 8;
  /// Buton · Kart
  static const double md = 12;
  /// Büyük kart
  static const double lg = 16;
  /// Sheet
  static const double xl = 20;
  /// Avatar · pill buton
  static const double full = 999;
}

/// Component ölçüleri (Figma: 04 — Components).
abstract final class AppSize {
  // Button — pill (radius.full), 3 boyut
  static const double buttonLarge = 52;
  static const double buttonMedium = 48;
  static const double buttonSmall = 40;
  static const double buttonPadHLarge = 20;
  static const double buttonPadHMedium = 16;
  static const double buttonPadHSmall = 12;
  static const double buttonGapLarge = 8;
  static const double buttonGapSmall = 6;

  /// Buton içi ikon.
  static const double iconInButton = 20;
  /// Lucide ikon seti — 24dp, 1.5dp stroke.
  static const double icon = 24;
  static const double iconStroke = 1.5;

  static const double minTouchTarget = 48;
}
