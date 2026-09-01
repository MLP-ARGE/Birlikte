import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_typography.dart';

/// Ayar listesi satırı (Figma: `profile` 3:1472 — ikon rozeti 40,
/// etiket solda, isteğe bağlı değer sağda, chevron 20).
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;

  /// Sağda gösterilen ikincil bilgi ("2/3", "Türkçe", "6 kategori").
  final String? value;
  final VoidCallback? onTap;

  static const badgeSize = 40.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s5,
            vertical: 14,
          ),
          child: Row(
            children: [
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.surfaceSunken,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: badgeSize,
                  child: Center(
                    child: Icon(icon, size: 20, color: AppColors.iconDefault),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (value case final value?) ...[
                Text(
                  value,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
              ],
              const Icon(
                AppIcons.chevronRight,
                size: 20,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bölüm başlığı + kart ("HESABIM", "UYGULAMA", "YASAL VE DESTEK").
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.s2,
            bottom: AppSpacing.s3,
          ),
          child: Text(
            title,
            style: AppTypography.overline.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            children: [
              for (final (i, child) in children.indexed) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    // İkon rozetinin sağından başlasın (16 + 40 + 14).
                    indent: 70,
                    color: AppColors.borderDefault,
                  ),
                child,
              ],
            ],
          ),
        ),
      ],
    );
  }
}
