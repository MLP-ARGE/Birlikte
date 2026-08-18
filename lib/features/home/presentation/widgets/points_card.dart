import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/home_models.dart';

/// Puan kartı (Figma: `points-card` 201:173 — 133 yüksek, radius 16,
/// `surfaceInverse` zemin; üstte bakiye satırı, ayraç, altta kırılım).
class PointsCard extends StatelessWidget {
  const PointsCard({
    super.key,
    required this.summary,
    this.onTap,
    this.onSpendTap,
  });

  final PointsSummary summary;
  final VoidCallback? onTap;
  final VoidCallback? onSpendTap;

  /// Figma: bakiye satırı iç boşluğu sol/üst/alt 18, sağ 14; gap 14.
  static const _pad = 18.0;
  static const _iconWrap = 44.0;

  static final _number = NumberFormat.decimalPattern('tr_TR');

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceInverse,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_pad, _pad, 14, _pad),
              child: Row(
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBrandStrong,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(
                      dimension: _iconWrap,
                      child: Center(
                        child: Icon(
                          AppIcons.sparkles,
                          size: 22,
                          color: AppColors.textOnBrand,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Toplam puanın',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textOnBrand,
                          ),
                        ),
                        // Figma: labels gap 2.
                        const SizedBox(height: AppSpacing.s1),
                        Text(
                          _number.format(summary.total),
                          style: AppTypography.h2.copyWith(
                            color: AppColors.textOnBrand,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    AppIcons.chevronRight,
                    size: 22,
                    color: AppColors.textOnBrand,
                  ),
                ],
              ),
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderDefault,
          ),
          Padding(
            // Figma: kırılım satırı üst 12, alt 14.
            padding: const EdgeInsets.fromLTRB(_pad, AppSpacing.s4, _pad, 14),
            child: Row(
              children: [
                // Tek bir zengin metin: iki ayrı Flexible alanı eşit bölüşüp
                // uzun olanı gereksiz kırpıyordu.
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textOnInverseMuted,
                      ),
                      children: [
                        TextSpan(
                          text:
                              'Kullanılabilir '
                              '${_number.format(summary.usable)}',
                        ),
                        // Figma: ayraç beyaz, iki yanında 6 boşluk.
                        const TextSpan(
                          text: '  ·  ',
                          style: TextStyle(color: AppColors.textOnBrand),
                        ),
                        TextSpan(
                          text:
                              'Bekleyen '
                              '${_number.format(summary.pending)}',
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Figma: gruplar arası spacer 18.
                const SizedBox(width: 18),
                GestureDetector(
                  onTap: onSpendTap,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    'Puan kullan',
                    style: AppTypography.buttonSmall.copyWith(
                      color: AppColors.textOnBrand,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
