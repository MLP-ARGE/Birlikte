import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/birlikte_section_header.dart';
import '../../domain/home_models.dart';

/// "Kan İhtiyacı Olanlar" bölümü (Figma: `kandas-section` 205:427).
class KandasSection extends StatelessWidget {
  const KandasSection({
    super.key,
    required this.requests,
    this.onSeeAll,
    this.onSupport,
  });

  final List<BloodRequest> requests;
  final VoidCallback? onSeeAll;
  final ValueChanged<BloodRequest>? onSupport;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BirlikteSectionHeader(
          title: 'Kan İhtiyacı Olanlar',
          actionLabel: 'Tümünü Gör',
          onAction: onSeeAll,
        ),
        // Figma: bölüm içi gap 14.
        const SizedBox(height: 14),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            children: [
              for (final (i, request) in requests.indexed) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.borderDefault,
                  ),
                _RequestRow(
                  request: request,
                  onSupport: onSupport == null
                      ? null
                      : () => onSupport!(request),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Tüm talepler ilgili hastaneler tarafından doğrulanır.',
          style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request, required this.onSupport});

  final BloodRequest request;
  final VoidCallback? onSupport;

  static const _badgeSize = 44.0;

  @override
  Widget build(BuildContext context) {
    return Padding
    // Figma: satır iç boşluğu yatay 16, dikey 14; gap 14.
    (
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s5,
        vertical: 14,
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.statusErrorSubtle,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: _badgeSize,
              child: Center(
                child: Text(
                  request.bloodType,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textError,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        request.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h6.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (request.urgent) ...[
                      const SizedBox(width: AppSpacing.s3),
                      const _UrgentTag(),
                    ],
                  ],
                ),
                // Figma: info gap 3.
                const SizedBox(height: 3),
                Text(
                  request.hospital,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _SupportButton(onTap: onSupport),
        ],
      ),
    );
  }
}

/// "Acil" etiketi (Figma: `urgent` 205:443 — radius 4, `error50` zemin).
class _UrgentTag extends StatelessWidget {
  const _UrgentTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: AppColors.statusErrorSubtle,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            AppIcons.circleAlert,
            size: 12,
            color: AppColors.textError,
          ),
          const SizedBox(width: 3),
          Text(
            'Acil',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textError,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Destek ol" düğmesi (Figma: `support-btn` 205:451 — 34 yüksek, pill,
/// `surfaceSunken` zemin, yatay iç boşluk 14).
class _SupportButton extends StatelessWidget {
  const _SupportButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 34,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceSunken,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            'Destek ol',
            style: AppTypography.buttonSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
