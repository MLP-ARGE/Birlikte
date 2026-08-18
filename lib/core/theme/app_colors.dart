import 'package:flutter/material.dart';

/// Renk paleti.
///
/// !!! PLACEHOLDER !!!
/// Bu değerler Figma'dan (MLPCARE-BIRLIKTE) çekilecek gerçek tokenlarla
/// değiştirilecek. Uygulamanın hiçbir yerinde ham `Color(0x...)` kullanmayın;
/// her rengi buradan okuyun, böylece tasarım güncellemesi tek dosyada biter.
abstract final class AppColors {
  // Marka
  static const brand = Color(0xFF0057A8);
  static const brandDark = Color(0xFF003D75);
  static const brandLight = Color(0xFFE6EFF7);

  // Vurgu
  static const accent = Color(0xFF00A9A5);

  // Nötr
  static const ink = Color(0xFF1A1C1E);
  static const inkMuted = Color(0xFF5A6069);
  static const inkFaint = Color(0xFF8E959E);
  static const line = Color(0xFFE2E5E9);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF5F7F9);
  static const background = Color(0xFFFAFBFC);

  // Durum
  static const success = Color(0xFF1E9E62);
  static const warning = Color(0xFFE0A126);
  static const danger = Color(0xFFD64545);
  static const info = Color(0xFF2F80ED);

  // Koyu tema nötrleri
  static const inkDark = Color(0xFFE6E8EA);
  static const inkMutedDark = Color(0xFFA8AEB6);
  static const lineDark = Color(0xFF2C3034);
  static const surfaceDark = Color(0xFF17191C);
  static const surfaceAltDark = Color(0xFF1F2225);
  static const backgroundDark = Color(0xFF101214);
}
