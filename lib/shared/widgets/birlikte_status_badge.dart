import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_typography.dart';

/// Rozetin anlamı — zemin ve metin rengini belirler.
enum BirlikteStatus { success, warning, error, info, neutral }

/// Durum rozeti (Figma: `verified-badge` 192:65 — pill, 28 yüksek, ikon 16,
/// iç boşluk sol 10 / sağ 12, gap 6).
class BirlikteStatusBadge extends StatelessWidget {
  const BirlikteStatusBadge({
    super.key,
    required this.label,
    this.status = BirlikteStatus.neutral,
    this.icon,
  });

  final String label;
  final BirlikteStatus status;

  /// Verilmezse duruma uygun varsayılan ikon kullanılır.
  final IconData? icon;

  Color get _background => switch (status) {
    BirlikteStatus.success => AppColors.statusSuccessSubtle,
    BirlikteStatus.warning => AppColors.statusWarningSubtle,
    BirlikteStatus.error => AppColors.statusErrorSubtle,
    BirlikteStatus.info => AppColors.statusInfoSubtle,
    BirlikteStatus.neutral => AppColors.statusNeutralSubtle,
  };

  Color get _foreground => switch (status) {
    BirlikteStatus.success => AppColors.textSuccess,
    BirlikteStatus.warning => AppColors.textWarning,
    BirlikteStatus.error => AppColors.textError,
    BirlikteStatus.info => AppColors.textInfo,
    BirlikteStatus.neutral => AppColors.textSecondary,
  };

  IconData get _icon =>
      icon ??
      switch (status) {
        BirlikteStatus.success => AppIcons.circleCheck,
        BirlikteStatus.warning || BirlikteStatus.error => AppIcons.circleAlert,
        BirlikteStatus.info || BirlikteStatus.neutral => AppIcons.info,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      // Figma: sol 10 / sağ 12 — ikon optik olarak daha fazla nefes istiyor.
      padding: const EdgeInsets.only(left: 10, right: AppSpacing.s4),
      height: 28,
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 16, color: _foreground),
          // Figma: gap 6.
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: _foreground),
          ),
        ],
      ),
    );
  }
}
