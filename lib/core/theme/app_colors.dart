import 'package:flutter/material.dart';

/// Ham renk ölçekleri (Figma: 02 — Foundations / Color · Primitives).
///
/// Ekranlarda **doğrudan kullanılmaz**. Yalnızca [AppColors] semantic
/// tokenları bunlara referans verir — Figma'daki kuralın aynısı.
abstract final class Palette {
  // brand — teal/cyan
  static const brand50 = Color(0xFFEFFCFD);
  static const brand100 = Color(0xFFDCF8FC);
  static const brand200 = Color(0xFFBCF2F8);
  static const brand300 = Color(0xFF8DE9F4);
  static const brand400 = Color(0xFF45DBED);
  static const brand500 = Color(0xFF14B9CC);
  static const brand600 = Color(0xFF1092A1);
  static const brand700 = Color(0xFF0D7480);
  static const brand800 = Color(0xFF0A5A64);
  static const brand900 = Color(0xFF07434A);
  static const brand950 = Color(0xFF052C31);

  // neutral
  static const neutral0 = Color(0xFFFFFFFF);
  static const neutral50 = Color(0xFFF8FAFB);
  static const neutral100 = Color(0xFFF1F4F6);
  static const neutral200 = Color(0xFFE5E9EC);
  static const neutral300 = Color(0xFFD2D8DD);
  static const neutral400 = Color(0xFFA0AAB1);
  static const neutral500 = Color(0xFF74818B);
  static const neutral600 = Color(0xFF5C6870);
  static const neutral700 = Color(0xFF47525A);
  static const neutral800 = Color(0xFF313B41);
  static const neutral900 = Color(0xFF1F262B);
  static const neutral950 = Color(0xFF11161A);

  // success
  static const success50 = Color(0xFFECFBF4);
  static const success100 = Color(0xFFD6F5E6);
  static const success300 = Color(0xFF5FD79B);
  static const success600 = Color(0xFF1F8452);
  static const success700 = Color(0xFF196B42);
  static const success800 = Color(0xFF145736);

  // warning
  static const warning50 = Color(0xFFFEF7EB);
  static const warning100 = Color(0xFFFDECCE);
  static const warning300 = Color(0xFFF0B95C);
  static const warning600 = Color(0xFFCE8509);
  static const warning700 = Color(0xFFA66C07);
  static const warning800 = Color(0xFF845606);

  // error
  static const error50 = Color(0xFFFDF0F0);
  static const error100 = Color(0xFFFAE1E0);
  static const error300 = Color(0xFFFF8A84);
  static const error600 = Color(0xFFB8231E);
  static const error700 = Color(0xFF9E1E1A);
  static const error800 = Color(0xFF7F1815);

  // info
  static const info50 = Color(0xFFEFF5FD);
  static const info100 = Color(0xFFDFEBFB);
  static const info300 = Color(0xFF7FB0F5);
  static const info600 = Color(0xFF185DBF);
  static const info700 = Color(0xFF144E9F);
}

/// Semantic tokenlar (Figma: 02 — Foundations / Semantic Tokens).
///
/// Ekranlarda **yalnızca bunlar** kullanılır.
///
/// Marka rengi iki katmanlıdır ve bu kasıtlıdır:
/// - [brand] (brand.600) → kimlik: logo, ≥24px ikon, aktif gösterge, border
/// - [actionPrimary] / [textBrand] (brand.700) → aksiyon: link, focus, puan değeri
///
/// Gerekçe Figma'da yazılı: brand.600 beyaz üzerinde 3.72:1 verir (büyük metin
/// ve UI için yeterli, gövde metni için değil), brand.700 ise 5.49:1 ile
/// tüm metin boyutlarında WCAG AA karşılar.
abstract final class AppColors {
  // Surface
  static const surface = Palette.neutral0;
  static const surfaceSubtle = Palette.neutral50;
  static const surfaceSunken = Palette.neutral100;
  static const surfaceBrand = Palette.brand50;
  static const surfaceBrandStrong = Palette.brand900;
  static const surfaceInverse = Palette.neutral900;
  static const background = Palette.neutral50;

  // Text
  static const textPrimary = Palette.neutral900;
  static const textSecondary = Palette.neutral600;
  static const textTertiary = Palette.neutral500;
  static const textBrand = Palette.brand700;
  static const textError = Palette.error600;
  static const textSuccess = Palette.success700;
  static const textWarning = Palette.warning800;
  static const textInfo = Palette.info700;
  static const textDisabled = Palette.neutral400;
  static const textOnBrand = Palette.neutral0;

  /// Koyu zemin üzerindeki ikincil metin (Figma: `points-card` alt satırı).
  /// Tasarım sisteminde adı yok, koyu kartlar için gerekli.
  static const textOnInverseMuted = Palette.neutral400;

  // Action
  static const actionPrimary = Palette.brand600;
  static const actionPrimaryPressed = Palette.brand700;
  static const actionSubtle = Palette.neutral100;
  static const actionDestructive = Palette.error600;
  static const actionDestructivePressed = Palette.error700;
  static const actionDisabled = Palette.neutral200;

  // Border & Icon
  static const borderDefault = Palette.neutral200;
  static const borderStrong = Palette.neutral300;
  static const borderBrand = Palette.brand600;
  static const borderFocus = Palette.brand600;
  static const borderError = Palette.error600;
  static const iconDefault = Palette.neutral700;
  static const iconSubtle = Palette.neutral500;
  static const iconBrand = Palette.brand600;

  // Status (subtle zeminler)
  static const statusSuccessSubtle = Palette.success50;
  static const statusWarningSubtle = Palette.warning50;
  static const statusErrorSubtle = Palette.error50;
  static const statusInfoSubtle = Palette.info50;
  static const statusNeutralSubtle = Palette.neutral100;

  /// Marka kimliği rengi — ikon, aktif gösterge, grafik. Gövde metni için
  /// [textBrand] kullanın.
  static const brand = Palette.brand600;
}
