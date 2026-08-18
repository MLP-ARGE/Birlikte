import 'package:flutter/material.dart';

/// Gölgeler (Figma: 02 — Foundations / Elevation).
///
/// Figma'daki kural: liste kartlarında gölge **yoktur** (elevation.0 + border).
/// Gölge yalnızca gerçek katmanlarda kullanılır: sticky bar, sheet, dialog, toast.
abstract final class AppElevation {
  static const _shadowColor = Color(0xFF0B1114);

  /// Kart · liste satırı — gölge yok, border ile ayrılır.
  static const List<BoxShadow> level0 = [];

  /// Aktif kupon kartı.
  static const List<BoxShadow> level1 = [
    BoxShadow(color: Color(0x0A0B1114), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x0F0B1114), offset: Offset(0, 1), blurRadius: 3),
  ];

  /// Sticky CTA · app bar.
  static const List<BoxShadow> level2 = [
    BoxShadow(color: Color(0x0D0B1114), offset: Offset(0, 2), blurRadius: 4),
    BoxShadow(color: Color(0x140B1114), offset: Offset(0, 4), blurRadius: 12),
  ];

  /// Sheet · dialog · toast.
  static const List<BoxShadow> level3 = [
    BoxShadow(color: Color(0x1A0B1114), offset: Offset(0, 8), blurRadius: 16),
    BoxShadow(color: Color(0x0F0B1114), offset: Offset(0, 2), blurRadius: 6),
  ];

  /// Sürüklenen öge.
  static const List<BoxShadow> level4 = [
    BoxShadow(color: Color(0x240B1114), offset: Offset(0, 16), blurRadius: 32),
  ];

  /// Figma'daki opaklıklar 0.04–0.14 aralığında; yukarıdaki ARGB sabitleri
  /// bunların 8-bit karşılığıdır (ör. 0.04 → 0x0A).
  static Color get shadowColor => _shadowColor;
}
