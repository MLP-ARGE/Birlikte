import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../home/application/home_providers.dart';
import '../../home/domain/home_models.dart';
import '../../home/presentation/widgets/points_card.dart';

/// Cüzdanım — puan özeti ve kullanıcının kuponları.
///
/// İçerik tamamen Supabase'den geliyor. Kupon yoksa uydurma satır
/// göstermiyoruz; ekran kendi boş durumunu anlatıyor.
class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(pointsSummaryProvider);
    final couponsAsync = ref.watch(couponsAsyncProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.s5,
            AppSpacing.screenH,
            AppSpacing.s8,
          ),
          children: [
            Text('Cüzdanım', style: AppTypography.h1),
            const SizedBox(height: AppSpacing.s5),
            PointsCard(summary: points),
            const SizedBox(height: AppSpacing.s7),
            Text('Kuponlarım', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.s4),
            switch (couponsAsync) {
              AsyncLoading() => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.s7),
                child: Center(child: CircularProgressIndicator()),
              ),
              AsyncError() => const _Empty(
                icon: AppIcons.ticket,
                text: 'Kuponlar yüklenemedi. Bağlantını kontrol edip '
                    'tekrar dene.',
              ),
              AsyncData(:final value) when value.isEmpty => const _Empty(
                icon: AppIcons.ticket,
                text: 'Henüz kuponun yok. Kampanyalar sekmesinden bir '
                    'kampanya seçip kuponunu oluşturabilirsin.',
              ),
              AsyncData(:final value) => Column(
                children: [
                  for (final c in value) ...[
                    _CouponCard(coupon: c),
                    const SizedBox(height: AppSpacing.s4),
                  ],
                ],
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({required this.coupon});

  final UserCoupon coupon;

  @override
  Widget build(BuildContext context) {
    // Kullanılmış ya da süresi dolmuş kuponu soluk gösteriyoruz; kullanıcı
    // hangisini kullanabileceğini listede tek bakışta ayırsın.
    final dim = !coupon.isActive;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s5),
      decoration: BoxDecoration(
        color: dim ? AppColors.surfaceSunken : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  coupon.brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                coupon.statusLabel,
                style: AppTypography.caption.copyWith(
                  color: dim ? AppColors.textTertiary : AppColors.textBrand,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            coupon.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.h5.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.s4),
          Row(
            children: [
              Text(
                coupon.code,
                style: AppTypography.campaignValue.copyWith(
                  color: dim ? AppColors.textTertiary : AppColors.textBrand,
                ),
              ),
              const Spacer(),
              if (coupon.expiresAt case final d? when coupon.isActive)
                Text(
                  '${d.day}.${d.month}.${d.year} tarihine kadar',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Boş durum — veri gelmediğinde ekranın ne anlattığını söyler.
class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s7),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.iconSubtle),
          const SizedBox(height: AppSpacing.s4),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
