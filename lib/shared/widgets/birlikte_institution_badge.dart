import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_institutions.dart';
import '../../core/theme/app_typography.dart';

/// Kurum/kapsam rozeti (Figma: `Badge / Institution` 144:309 — radius 4,
/// solda 3dp renkli şerit).
///
/// Tasarımda üç yükseklikte kullanılıyor: ana sayfa başlığında 20,
/// karşılama kartında 24, kampanya kartında 16.
class BirlikteInstitutionBadge extends StatelessWidget {
  /// Belirli bir kuruma ait rozet — şerit kurumun marka rengi.
  BirlikteInstitutionBadge({
    super.key,
    required Institution institution,
    this.height = 24,
  }) : label = institution.label,
       stripeColor = institution.color;

  /// Kampanya tüm kurumlara açıksa — şerit nötr (Figma: #A0AAB1).
  const BirlikteInstitutionBadge.allInstitutions({super.key, this.height = 16})
    : label = 'Tüm kurumlara özel',
      stripeColor = Palette.neutral400;

  final String label;
  final Color stripeColor;
  final double height;

  static const _stripeWidth = 3.0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: ColoredBox(
        color: AppColors.surfaceSunken,
        child: SizedBox(
          height: height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ColoredBox(
                color: stripeColor,
                child: SizedBox(width: _stripeWidth, height: height),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
                child: Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
