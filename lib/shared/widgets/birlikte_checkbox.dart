import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_typography.dart';

/// Onay kutusu + etiket (Figma: `Checkbox` 147:382 — kutu 24x24, radius 6,
/// 1.5dp `borderStrong` çerçeve; satır gap 12, dikey iç boşluk 10).
class BirlikteCheckbox extends StatelessWidget {
  const BirlikteCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  static const _boxSize = 24.0;
  static const _boxRadius = 6.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: _boxSize,
                height: _boxSize,
                decoration: BoxDecoration(
                  color: value ? AppColors.actionPrimary : AppColors.surface,
                  borderRadius: BorderRadius.circular(_boxRadius),
                  border: value
                      ? null
                      : Border.all(color: AppColors.borderStrong, width: 1.5),
                ),
                child: value
                    ? const Icon(
                        AppIcons.check,
                        size: 16,
                        color: AppColors.textOnBrand,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
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
