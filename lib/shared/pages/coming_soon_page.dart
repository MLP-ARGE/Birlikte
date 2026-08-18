import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../widgets/birlikte_bottom_nav.dart';

/// Henüz kurulmamış sekmeler için iskele ekran.
///
/// Figma'da bu bölümlerin tasarımı var (kampanyalar, cüzdan, Kandaş, profil);
/// hazır olana kadar alt navigasyon çalışsın diye buraya düşülüyor. Ürün
/// ekranı değil — ilgili bölüm kurulunca silinecek.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.tab});

  final BirlikteTab tab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tab.icon, size: 48, color: AppColors.iconSubtle),
                const SizedBox(height: AppSpacing.s5),
                Text(
                  tab.label,
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s3),
                Text(
                  'Bu bölüm henüz hazır değil.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BirlikteBottomNav(
        current: tab,
        onSelected: (next) => context.go(next.route),
      ),
    );
  }
}
