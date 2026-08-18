import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/birlikte_avatar.dart';
import '../../../../shared/widgets/birlikte_institution_badge.dart';
import '../../../auth/domain/verified_profile.dart';

/// Ana sayfa başlığı (Figma: `app-header` 201:125 — 61 yüksek, gap 12,
/// iç boşluk sol 24 / sağ 14, üst 4 / alt 12).
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.profile,
    required this.hasNotifications,
    this.onNotificationsTap,
  });

  final VerifiedProfile profile;
  final bool hasNotifications;
  final VoidCallback? onNotificationsTap;

  static const _bellSize = 44.0;
  static const _dotSize = 9.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.s2,
        14,
        AppSpacing.s4,
      ),
      child: Row(
        children: [
          BirlikteAvatar(
            name: profile.fullName,
            imageUrl: profile.photoUrl,
            size: 40,
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merhaba, ${profile.firstName}',
                  style: AppTypography.h4.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                // Figma: greeting gap 1.
                const SizedBox(height: 1),
                BirlikteInstitutionBadge(
                  institution: profile.institution,
                  height: 20,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          _NotificationBell(
            hasUnread: hasNotifications,
            onTap: onNotificationsTap,
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.hasUnread, required this.onTap});

  final bool hasUnread;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: hasUnread ? 'Okunmamış bildirim var' : 'Bildirimler',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: HomeHeader._bellSize,
          child: Stack(
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceSunken,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    AppIcons.bell,
                    size: 22,
                    color: AppColors.iconDefault,
                  ),
                ),
              ),
              if (hasUnread)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: HomeHeader._dotSize,
                    height: HomeHeader._dotSize,
                    decoration: BoxDecoration(
                      color: AppColors.textError,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface),
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
