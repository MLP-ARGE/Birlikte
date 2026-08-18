import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_typography.dart';

/// Bilgilendirme kartı (Figma: `Card / Info` 151:879 — radius 12,
/// `surfaceSunken` zemin, iç boşluk 14, ikon 20, gap 10).
class BirlikteInfoCard extends StatelessWidget {
  const BirlikteInfoCard({super.key, required this.message, this.icon});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Figma'da 14 ve 10 — 4dp ölçeğinin dışında, tokenı yok.
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? AppIcons.info,
            size: AppSize.iconInButton,
            color: AppColors.iconDefault,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
