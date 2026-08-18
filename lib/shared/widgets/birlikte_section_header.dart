import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_typography.dart';

/// Bölüm başlığı (Figma: `Section Header` 151:913 — başlık 20/600, sağda
/// eylem 14/600 + 16dp chevron, dikey iç boşluk 4).
class BirlikteSectionHeader extends StatelessWidget {
  const BirlikteSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
            ),
          ),
          if (actionLabel case final actionLabel?)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(
                    actionLabel,
                    style: AppTypography.buttonSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  // Figma: eylem içi gap 4.
                  const SizedBox(width: AppSpacing.s2),
                  const Icon(
                    AppIcons.chevronRight,
                    size: 16,
                    color: AppColors.iconDefault,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
