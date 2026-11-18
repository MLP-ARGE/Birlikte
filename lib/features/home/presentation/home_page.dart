import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/app_config/app_open_tracker.dart';
import '../../../core/push/push_notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../shared/widgets/birlikte_campaign_card.dart';
import '../../../shared/widgets/birlikte_section_header.dart';
import '../../auth/application/verified_profile_provider.dart';
import '../../auth/data/profile_repository.dart';
import '../../notifications/application/notification_providers.dart';
import '../application/home_providers.dart';
import '../domain/home_models.dart';
import 'widgets/ailem_section.dart';
import 'widgets/app_update_prompt.dart';
import 'widgets/home_header.dart';
import 'widgets/kandas_section.dart';
import 'widgets/missing_info_sheet.dart';
import 'widgets/points_card.dart';
import 'widgets/quick_tiles.dart';

/// Ana sayfa (Figma: `home-page` 199:298).
///
/// Bölümler: hızlı erişim, puan kartı, "Kampanyalar", "Kan İhtiyacı
/// Olanlar", "Ailem". Alt navigasyon 5 sekme.
///
/// "Sana Özel" bölümü kaldırıldı — gerçek kampanya kaydına karşılık
/// gelmeyen, sabit kodlanmış iki örnek kartı gösteriyordu ("İncele"
/// dokununca "Kampanya Bulunamadı" veriyordu).
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
    // Giriş yapıldıktan sonra cinsiyet/ad/soyad eksikse bir kez bilgi
    // sheet'i gösterilir — giriş engellenmez, bu yalnızca bir hatırlatma.
    // Yeni kullanıcı zaten WelcomePage'de görür; bu, Welcome'ı atlayan
    // dönen kullanıcılar için bir yedek (ikisi aynı bayrağı paylaşıyor,
    // iki kez gösterilmiyor).
    maybeShowMissingInfoSheet(context, ref, ref.watch(profileProvider).value);
    // Aynı gerekçeyle: bildirim izni/push token senkronizasyonu da Welcome'ı
    // atlayan dönen kullanıcılar için burada bir kez tetiklenir.
    ensurePushTokenSynced(ref);
    // Splash'ta tespit edilen ÖNERİLEN güncelleme/duyuru (varsa) burada bir
    // kez gösterilir — bakım/ZORUNLU güncelleme splash'ın kendi ekranları.
    maybeShowAppNotice(context, ref);
    // Aynı gerekçeyle: soğuk başlangıç açılış kaydı (`POST /api/me/acilis`)
    // da Welcome'ı atlayan dönen kullanıcılar için burada bir kez tetiklenir.
    ensureAppOpenRecorded(ref);

    final profile = ref.watch(verifiedProfileProvider);
    final points = ref.watch(pointsSummaryProvider);
    final campaigns = ref.watch(endingSoonCampaignsProvider);
    final requests = ref.watch(bloodRequestsProvider);
    final favorites = ref.watch(favoriteSlugsProvider);
    final members = ref.watch(familyMembersProvider);

    // Karuseller ekran kenarına kadar kaydığı için yatay boşluk bölüm bölüm
    // veriliyor, sayfanın tamamına değil.
    Widget inset(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: child,
    );

    // Kampanyalar sekmesi IndexedStack'te canlı kaldığından önceki
    // ziyaretten kalma filtre/arama burada sıfırlanmazsa, buradan "Tümünü
    // Gör"le girenler beklediği TÜM kampanyalar yerine eski filtreyle
    // karşılaşır.
    void goToAllCampaigns() {
      ref.read(campaignsFilterResetProvider.notifier).bump();
      refreshCampaignsData(ref);
      context.go(Routes.campaigns);
    }

    // Cüzdanım da IndexedStack'te canlı kalıyor — her girişte kuponlar/puan
    // tazelenmezse, başka yerden iptal edilen bir kupon burada bayat
    // görünmeye devam eder (bkz. `refreshWalletData`).
    void goToWallet() {
      refreshWalletData(ref);
      context.go(Routes.wallet);
    }

    // Kampanya detayı `campaignDetailAsyncProvider` ile ayrı bir uçtan
    // okunuyor ve autoDispose değil — destek ekibi kuponu iptal ederse
    // (kuponAldim tekrar false'a döner) kullanıcı aynı kampanyaya tekrar
    // girdiğinde bunu görmeli, bayat önbellekte kalmamalı.
    void openCampaign(String id) {
      ref.invalidate(campaignDetailAsyncProvider(id));
      context.push(Routes.campaignDetail(id));
    }

    // Bildirimler listesi autoDispose değil — ekrana her girişte taze
    // (okunmamış sayısı dahil) gösterilsin diye önce invalidate ediliyor.
    void openNotifications() {
      ref.invalidate(notificationsProvider);
      context.push(Routes.notifications);
    }

    // Aşağı çekip yenileme: ekrandaki her bölümü besleyen uçları tazeler.
    Future<void> onRefresh() => Future.wait([
      ref.refresh(profileProvider.future),
      ref.refresh(campaignsAsyncProvider.future),
      ref.refresh(pointsSummaryAsyncProvider.future),
      ref.refresh(bloodRequestsAsyncProvider.future),
      ref.refresh(familyMembersAsyncProvider.future),
    ]);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            HomeHeader(profile: profile, onNotificationsTap: openNotifications),
            Expanded(
              child: RefreshIndicator(
                onRefresh: onRefresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                  children: [
                    inset(
                      QuickTiles(
                        tiles: [
                          QuickTile(
                            label: 'Kuponlar',
                            icon: AppIcons.ticket,
                            onTap: goToWallet,
                          ),
                          QuickTile(
                            label: 'Puanlar',
                            icon: AppIcons.sparkles,
                            onTap: goToWallet,
                          ),
                          QuickTile(
                            label: 'Kampanya',
                            icon: AppIcons.ticketPercent,
                            onTap: goToAllCampaigns,
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
                        onTap: goToWallet,
                        onSpendTap: goToWallet,
                      ),
                    ),
                    const SizedBox(height: _sectionGap),
                    inset(
                      BirlikteSectionHeader(
                        title: 'Kampanyalar',
                        actionLabel: 'Tümünü Gör',
                        onAction: goToAllCampaigns,
                      ),
                    ),
                    const SizedBox(height: _headerGap),
                    _CampaignCarousel(
                      campaigns: campaigns,
                      height: _campaignCarouselHeight,
                      favorites: favorites,
                      onOpen: openCampaign,
                      onToggleFavorite: (id) =>
                          toggleCampaignFavorite(context, ref, id),
                    ),
                    const SizedBox(height: _sectionGap),
                    inset(
                      KandasSection(
                        requests: requests,
                        onSeeAll: () => context.go(Routes.kandas),
                        onSupport: (request) =>
                            toggleBloodRequestApplication(ref, request),
                      ),
                    ),
                    const SizedBox(height: _sectionGap),
                    inset(AilemSection(members: members)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Kampanyalar" karuseli (Figma: `card-carousel` 201:237 — gap 12).
class _CampaignCarousel extends StatelessWidget {
  const _CampaignCarousel({
    required this.campaigns,
    required this.height,
    required this.favorites,
    required this.onOpen,
    required this.onToggleFavorite,
  });

  final List<Campaign> campaigns;
  final double height;
  final Set<String> favorites;
  final ValueChanged<String> onOpen;
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
            onTap: () => onOpen(campaign.id),
            onFavoriteTap: () => onToggleFavorite(campaign.id),
          );
        },
      ),
    );
  }
}
