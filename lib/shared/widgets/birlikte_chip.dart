import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';

/// Seçilebilir pill (Figma: `group-button` 215:477 — 40 yüksek, radius full,
/// yatay iç boşluk 16, etiket 14/500).
///
/// Seçili: `actionPrimary` zemin + beyaz metin. Seçili değil: `surfaceSunken`
/// zemin + `textPrimary`.
class BirlikteChip extends StatelessWidget {
  const BirlikteChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Figma: 40 yüksek, etiket satır yüksekliği 18 → dikey dolgu 11.
  /// Yüksekliği `height` ile vermek yerine dolgudan kuruyoruz: `Container`'a
  /// `alignment` verilince gelen maksimum genişliği doldurur ve [Wrap] içinde
  /// chip'ler yan yana dizilmez.
  static const _verticalPad = 11.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s5,
            vertical: _verticalPad,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.actionPrimary
                : AppColors.surfaceSunken,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          // `labelMedium`'ın satır yüksekliği (18/14) fontun kendi
          // ascent/descent oranından fazla boşluk ekliyor; bu boşluk üstte
          // ve altta eşit dağılmadığı için eşit dolgulu bu pilde metin hafif
          // kaymış görünüyordu. `textHeightBehavior` bu fazlalığı kırpıp
          // metni gerçek glif sınırlarına oturtuyor.
          child: Text(
            label,
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
            style: AppTypography.labelMedium.copyWith(
              color: selected
                  ? AppColors.textOnBrand
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
