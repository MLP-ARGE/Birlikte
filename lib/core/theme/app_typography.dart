import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tipografi skalası.
///
/// !!! PLACEHOLDER !!!
/// [fontFamily] Figma'daki gerçek yazı tipiyle değişecek. Font dosyaları
/// assets/fonts/ altına konup pubspec.yaml'da tanımlanacak; o zamana kadar
/// null bırakılıyor ve platform varsayılanı (SF Pro / Roboto) kullanılıyor.
abstract final class AppTypography {
  static const String? fontFamily = null;

  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 34, height: 1.2, fontWeight: FontWeight.w700, letterSpacing: -0.5),
    displayMedium: TextStyle(fontSize: 28, height: 1.25, fontWeight: FontWeight.w700, letterSpacing: -0.3),
    headlineLarge: TextStyle(fontSize: 24, height: 1.3, fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(fontSize: 20, height: 1.3, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontSize: 18, height: 1.35, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 16, height: 1.4, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w400),
    bodySmall: TextStyle(fontSize: 12, height: 1.45, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontSize: 15, height: 1.2, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontSize: 13, height: 1.2, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: 11, height: 1.2, fontWeight: FontWeight.w500),
  );

  static TextTheme applied({required bool dark}) => textTheme.apply(
        fontFamily: fontFamily,
        bodyColor: dark ? AppColors.inkDark : AppColors.ink,
        displayColor: dark ? AppColors.inkDark : AppColors.ink,
      );
}
