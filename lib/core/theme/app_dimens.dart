/// Boşluk, yarıçap ve ölçü sabitleri.
///
/// !!! PLACEHOLDER !!! Figma'daki gerçek spacing/radius skalasıyla değişecek.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Ekranların standart yatay kenar boşluğu.
  static const double screenH = 20;
}

abstract final class AppRadius {
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
}

abstract final class AppSize {
  static const double buttonHeight = 52;
  static const double inputHeight = 52;
  static const double iconSm = 16;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double touchTarget = 48;
}
