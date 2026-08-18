import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tipografi (Figma: 02 — Foundations / Typography, 25 text style).
///
/// Gövde yazı tipi **Inter**, kupon kodları **JetBrains Mono**.
///
/// Her ikisi de *variable* font olarak bundle'lanır. Flutter, variable
/// fontlarda [TextStyle.fontWeight] değerini `wght` eksenine kendiliğinden
/// uygulamaz; bu yüzden aşağıdaki yardımcılar `fontWeight` ile birlikte
/// [FontVariation] da verir. Yeni stil eklerken bu yardımcıları kullanın,
/// doğrudan [TextStyle] yazmayın — aksi hâlde ağırlık 400'e düşer.
abstract final class AppTypography {
  static const String sans = 'Inter';
  static const String mono = 'JetBrainsMono';

  static TextStyle _sans(
    double size,
    double lineHeight,
    int weight, {
    double? letterSpacing,
    Color? color = AppColors.textPrimary,
  }) =>
      TextStyle(
        fontFamily: sans,
        fontSize: size,
        height: lineHeight / size,
        fontWeight: FontWeight.values[weight ~/ 100 - 1],
        fontVariations: [FontVariation('wght', weight.toDouble())],
        letterSpacing: letterSpacing,
        color: color,
      );

  static TextStyle _mono(
    double size,
    double lineHeight,
    int weight, {
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: mono,
        fontSize: size,
        height: lineHeight / size,
        fontWeight: FontWeight.values[weight ~/ 100 - 1],
        fontVariations: [FontVariation('wght', weight.toDouble())],
        letterSpacing: letterSpacing,
        color: AppColors.textPrimary,
      );

  // Display & Heading
  static final display = _sans(32, 38, 700, letterSpacing: -0.64);
  static final h1 = _sans(28, 34, 700, letterSpacing: -0.56);
  static final h2 = _sans(24, 30, 700, letterSpacing: -0.36);
  static final h3 = _sans(20, 26, 600, letterSpacing: -0.2);
  static final h4 = _sans(18, 24, 600);
  static final h5 = _sans(16, 22, 600);
  static final h6 = _sans(14, 20, 600);

  // Title & Subtitle
  static final title = _sans(17, 22, 600);
  static final subtitle = _sans(15, 20, 500);

  // Body
  static final bodyLarge = _sans(16, 24, 400);
  static final bodyMedium = _sans(15, 22, 400);
  static final bodySmall = _sans(14, 20, 400);

  // Label
  static final labelLarge = _sans(15, 20, 500);
  static final labelMedium = _sans(14, 18, 500);
  static final labelSmall = _sans(12, 16, 500, letterSpacing: 0.12);

  // Button — rengi kullanım yerinde belirlenir
  static final buttonLarge = _sans(17, 22, 600, color: null);
  static final buttonMedium = _sans(16, 20, 600, color: null);
  static final buttonSmall = _sans(14, 18, 600, color: null);

  // Yardımcı
  static final caption = _sans(12, 16, 400, letterSpacing: 0.12);
  static final overline = _sans(12, 16, 600, letterSpacing: 0.96);

  // Sayısal
  static final numericDefault = _sans(20, 26, 600, letterSpacing: -0.2);
  static final numericLarge = _sans(32, 38, 700, letterSpacing: -0.64);
  static final promotionalValue = _sans(22, 28, 700, letterSpacing: -0.22);

  // Kupon kodu — monospace
  static final couponCodeLarge = _mono(24, 32, 700, letterSpacing: 2.88);
  static final couponCodeSmall = _mono(15, 20, 500, letterSpacing: 1.2);

  /// Figma stillerinin en yakın Material yuvalarına eşlenmesi. Ekranlarda
  /// yukarıdaki adlandırılmış stiller tercih edilir; bu eşleme yalnızca
  /// Material widget'larının varsayılanları için.
  static TextTheme get textTheme => TextTheme(
        displayLarge: display,
        displayMedium: h1,
        displaySmall: h2,
        headlineLarge: h2,
        headlineMedium: h3,
        headlineSmall: h4,
        titleLarge: title,
        titleMedium: h5,
        titleSmall: h6,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );
}
