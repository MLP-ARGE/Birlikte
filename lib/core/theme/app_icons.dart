import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Uygulamanın ikon seti (Figma: 04 — Components / Icons, 73 Lucide ikonu).
///
/// Tasarım **24dp / 1.5 stroke** istiyor. `lucide_icons_flutter` stroke'u ayrı
/// font ailelerinde sunuyor ve ölçtüğümüz eşleme `ağırlık / 200 = stroke`:
/// `400` → 2.0, `600` → 3.0, **`300` → 1.5**. Bu yüzden tüm ikonlar `300`
/// varyantından alınır — düz `LucideIcons.foo` kullanılmamalı, o 2.5 stroke.
///
/// Yeni ikon eklerken buraya `<ad>300` olarak ekleyin; ekranlarda doğrudan
/// `LucideIcons` kullanmayın.
abstract final class AppIcons {
  // Navigasyon
  static const IconData arrowLeft = LucideIcons.arrowLeft300;
  static const IconData arrowRight = LucideIcons.arrowRight300;
  static const IconData chevronRight = LucideIcons.chevronRight300;
  static const IconData chevronDown = LucideIcons.chevronDown300;
  static const IconData close = LucideIcons.x300;

  // Durum & geri bildirim
  static const IconData check = LucideIcons.check300;
  static const IconData circleCheck = LucideIcons.circleCheck300;
  static const IconData circleAlert = LucideIcons.circleAlert300;
  static const IconData info = LucideIcons.info300;
  static const IconData clock = LucideIcons.clock300;
  static const IconData triangleAlert = LucideIcons.triangleAlert300;

  // Ana sayfa & navigasyon
  static const IconData house = LucideIcons.house300;
  static const IconData ticket = LucideIcons.ticket300;
  static const IconData ticketPercent = LucideIcons.ticketPercent300;
  static const IconData sparkles = LucideIcons.sparkles300;
  static const IconData droplet = LucideIcons.droplet300;
  static const IconData wallet = LucideIcons.wallet300;
  static const IconData user = LucideIcons.user300;
  static const IconData bell = LucideIcons.bell300;
  static const IconData heart = LucideIcons.heart300;
  static const IconData plus = LucideIcons.plus300;
  static const IconData gift = LucideIcons.gift300;
  static const IconData userPlus = LucideIcons.userPlus300;

  // Kurum & kimlik
  static const IconData building = LucideIcons.building2300;
  static const IconData idCard = LucideIcons.idCard300;
  static const IconData phone = LucideIcons.phone300;
}
