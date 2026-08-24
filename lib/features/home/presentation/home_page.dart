import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../shared/widgets/birlikte_campaign_card.dart';
import '../../../shared/widgets/birlikte_section_header.dart';
import '../../auth/application/verified_profile_provider.dart';
import '../application/home_providers.dart';
import '../domain/home_models.dart';
import 'widgets/ailem_section.dart';
import 'widgets/home_header.dart';
import 'widgets/kandas_section.dart';
import 'widgets/points_card.dart';
import 'widgets/promo_carousel.dart';
import 'widgets/quick_tiles.dart';

/// Ana sayfa (Figma: `home-page` 199:298).
///
/// Bölümler: hızlı erişim, puan kartı, "Sana Özel", "Yakında Sona Erecek",
/// "Kan İhtiyacı Olanlar", "Ailem". Alt navigasyon 5 sekme.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// Figma `scroll-content`: bölümler arası 16.
  static const _sectionGap = AppSpacing.s5;

  /// Bölüm başlığı ile içeriği arası.
  static const _headerGap = 14.0;

  /// Kampanya karuseli yüksekliği (Figma: `Card / Campaign` 348).
  static const _campaignCarouselHeight = 348.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(verifiedProfileProvider);
    final points = ref.watch(pointsSummaryProvider);
    final offers = ref.watch(promoOffersProvider);
    final campaigns = ref.watch(endingSoonCampaignsProvider);
    final requests = ref.watch(bloodRequestsProvider);
    final favorites = ref.watch(favoriteCampaignIdsProvider);
    final members = ref.watch(familyMembersProvider);
    final capacity = ref.watch(familyCapacityProvider);

    // Karuseller ekran kenarına kadar kaydığı için yatay boşluk bölüm bölüm
    // veriliyor, sayfanın tamamına değil.
    Widget inset(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: child,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            HomeHeader(profile: profile, hasNotifications: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                children: [
                  inset(
                    QuickTiles(
                      tiles: [
                        QuickTile(
                          label: 'Kuponlar',
                          icon: AppIcons.ticket,
                          onTap: () => context.go(Routes.wallet),
                        ),
                        QuickTile(
                          label: 'Puanlar',
                          icon: AppIcons.sparkles,
                          onTap: () => context.go(Routes.wallet),
                        ),
                        QuickTile(
                          label: 'Kampanya',
                          icon: AppIcons.ticketPercent,
                          onTap: () => context.go(Routes.campaigns),
                        ),
                        QuickTile(
                          label: 'Kandaş',
                          icon: AppIcons.droplet,
                          onTap: () => context.go(Routes.kandas),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: _sectionGap),
                  inset(
                    PointsCard(
                      summary: points,
                      onTap: () => context.go(Routes.wallet),
                      onSpendTap: () => context.go(Routes.wallet),
                    ),
                  ),
                  const SizedBox(height: _sectionGap),
                  inset(
                    BirlikteSectionHeader(
                      title: 'Sana Özel',
                      actionLabel: 'Tümünü Gör',
                      onAction: () => context.go(Routes.campaigns),
                    ),
                  ),
                  const SizedBox(height: _headerGap),
                  PromoCarousel(
                    offers: offers,
                    onOfferTap: (offer) {
                      if (offer.campaignId case final id?) {
                        context.push(Routes.campaignDetail(id));
                      }
                    },
                  ),
                  const SizedBox(height: _sectionGap),
                  inset(
                    BirlikteSectionHeader(
                      title: 'Yakında Sona Erecek',
                      actionLabel: 'Tümünü Gör',
                      onAction: () => context.go(Routes.campaigns),
                    ),
                  ),
                  const SizedBox(height: _headerGap),
                  _CampaignCarousel(
                    campaigns: campaigns,
                    height: _campaignCarouselHeight,
                    favorites: favorites,
                    onToggleFavorite: (id) => ref
                        .read(favoriteCampaignIdsProvider.notifier)
                        .toggle(id),
                  ),
                  const SizedBox(height: _sectionGap),
                  inset(KandasSection(requests: requests)),
                  const SizedBox(height: _sectionGap),
                  inset(
                    AilemSection(members: members, capacity: capacity),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Yakında Sona Erecek" karuseli (Figma: `card-carousel` 201:237 — gap 12).
class _CampaignCarousel extends StatelessWidget {
  const _CampaignCarousel({
    required this.campaigns,
    required this.height,
    required this.favorites,
    required this.onToggleFavorite,
  });

  final List<Campaign> campaigns;
  final double height;
  final Set<String> favorites;
  final ValueChanged<String> onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        itemCount: campaigns.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s4),
        itemBuilder: (context, i) {
          final campaign = campaigns[i];
          return BirlikteCampaignCard(
            campaign: campaign,
            isFavorite: favorites.contains(campaign.id),
            onTap: () => context.push(Routes.campaignDetail(campaign.id)),
            onFavoriteTap: () => onToggleFavorite(campaign.id),
          );
        },
      ),
    );
  }
}
