import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/birlikte_app_bar.dart';
import '../../../shared/widgets/birlikte_campaign_card.dart';
import '../../home/application/home_providers.dart';

/// Favori kampanyalarım (Profil → "Favori kampanyalar").
///
/// Daha önce bu satır genel Kampanyalar sekmesine yönlendiriyordu — favori
/// olmayanlar da dahil tüm listeyi gösteriyordu. Artık yalnızca
/// [favoriteCampaignsProvider]'ı (tek kaynak kampanya listesinden süzülmüş)
/// gösteriyor.
class FavoriteCampaignsPage extends ConsumerWidget {
  const FavoriteCampaignsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteCampaignsProvider);
    final favoriteIds = ref.watch(favoriteSlugsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BirlikteAppBar(onBack: () => context.pop()),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
              ),
              child: Text('Favori Kampanyalarım', style: AppTypography.h1),
            ),
            const SizedBox(height: AppSpacing.s5),
            Expanded(
              child: favorites.isEmpty
                  ? const _Empty()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenH,
                        0,
                        AppSpacing.screenH,
                        AppSpacing.s8,
                      ),
                      itemCount: favorites.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.s5),
                      itemBuilder: (context, i) {
                        final campaign = favorites[i];
                        return BirlikteCampaignCard(
                          campaign: campaign,
                          width: double.infinity,
                          imageHeight: 198,
                          isFavorite: favoriteIds.contains(campaign.id),
                          onTap: () =>
                              context.push(Routes.campaignDetail(campaign.id)),
                          onFavoriteTap: () =>
                              toggleCampaignFavorite(context, ref, campaign.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.heart, size: 48, color: AppColors.iconSubtle),
            const SizedBox(height: AppSpacing.s5),
            Text(
              'Henüz favori kampanyan yok',
              style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Beğendiğin kampanyaları kalp ikonuna dokunarak buraya '
              'ekleyebilirsin.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
