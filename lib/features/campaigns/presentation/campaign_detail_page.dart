import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/birlikte_button.dart';
import '../../../shared/widgets/birlikte_info_card.dart';
import '../../home/application/home_providers.dart';
import '../../home/domain/home_models.dart';
import 'widgets/coupon_create_sheet.dart';

/// Kampanya detayı (Figma: `campaign-detail` 3:686, `campaign-terms` 3:9005,
/// `campaign-branches` 3:9110 — üçü aynı ekranın farklı sekmeleridir).
class CampaignDetailPage extends ConsumerStatefulWidget {
  const CampaignDetailPage({super.key, required this.campaignId});

  final String campaignId;

  @override
  ConsumerState<CampaignDetailPage> createState() =>
      _CampaignDetailPageState();
}

enum _Tab { details, terms, branches }

class _CampaignDetailPageState extends ConsumerState<CampaignDetailPage> {
  _Tab _tab = _Tab.details;

  static const _heroHeight = 300.0;

  @override
  Widget build(BuildContext context) {
    final campaign = ref.watch(campaignByIdProvider(widget.campaignId));
    if (campaign == null) return const _CampaignNotFound();

    final favorites = ref.watch(favoriteSlugsProvider);
    final isFavorite = favorites.contains(campaign.id);
    final tabs = [
      _Tab.details,
      if (campaign.hasTermsDetail) _Tab.terms,
      if (campaign.branches.isNotEmpty) _Tab.branches,
    ];
    final activeTab = tabs.contains(_tab) ? _tab : _Tab.details;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _Hero(
            campaign: campaign,
            height: _heroHeight,
            isFavorite: isFavorite,
            onBack: () => context.pop(),
            onFavoriteTap: () => ref
                .read(favoriteCampaignIdsProvider.notifier)
                .toggle(campaign.id),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.s5,
                AppSpacing.screenH,
                AppSpacing.s7,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BrandRow(campaign: campaign),
                  const SizedBox(height: AppSpacing.s5),
                  Text(campaign.title, style: AppTypography.h2),
                  if (campaign.description case final description?) ...[
                    const SizedBox(height: AppSpacing.s3),
                    Text(
                      description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (campaign.tags.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s4),
                    Wrap(
                      spacing: AppSpacing.s3,
                      runSpacing: AppSpacing.s3,
                      children: [
                        for (final tag in campaign.tags) _DetailTag(tag),
                      ],
                    ),
                  ],
                  if (tabs.length > 1) ...[
                    const SizedBox(height: AppSpacing.s6),
                    _UnderlineTabs(
                      tabs: tabs,
                      active: activeTab,
                      onChanged: (t) => setState(() => _tab = t),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s5),
                  switch (activeTab) {
                    _Tab.details => _DetailsTab(campaign: campaign),
                    _Tab.terms => _TermsTab(campaign: campaign),
                    _Tab.branches => _BranchesTab(campaign: campaign),
                  },
                  const SizedBox(height: AppSpacing.s7),
                  _SecondaryActions(
                    isFavorite: isFavorite,
                    onFavoriteTap: () => ref
                        .read(favoriteCampaignIdsProvider.notifier)
                        .toggle(campaign.id),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.s3,
            AppSpacing.screenH,
            AppSpacing.s3,
          ),
          child: BirlikteButton(
            label: 'Kupon Oluştur',
            onPressed: () => showCouponCreateSheet(context, campaign),
          ),
        ),
      ),
    );
  }
}

class _CampaignNotFound extends StatelessWidget {
  const _CampaignNotFound();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(AppIcons.arrowLeft, color: AppColors.iconDefault),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Text(
          'Kampanya bulunamadı',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Görsel üstü aksiyonlar (Figma: `hero` 240:607 — 300 yüksek, geri/paylaş/
/// favori 44x44 beyaz yuvarlak düğmeler).
///
/// Gerçek fotoğraf uygulamaya gömülmedi; marka rengi zemin + hediye ikonu
/// Figma'nın kendi yer tutucusu (kampanya kartlarındakiyle aynı desen).
class _Hero extends StatelessWidget {
  const _Hero({
    required this.campaign,
    required this.height,
    required this.isFavorite,
    required this.onBack,
    required this.onFavoriteTap,
  });

  final Campaign campaign;
  final double height;
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          const Positioned.fill(
            child: ColoredBox(
              color: AppColors.surfaceBrand,
              child: Center(
                child: Icon(
                  AppIcons.gift,
                  size: 48,
                  color: AppColors.iconBrand,
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s3,
                vertical: AppSpacing.s2,
              ),
              child: Row(
                children: [
                  _HeroButton(
                    icon: AppIcons.arrowLeft,
                    label: 'Geri',
                    onTap: onBack,
                  ),
                  const Spacer(),
                  _HeroButton(
                    icon: AppIcons.share,
                    label: 'Paylaş',
                    onTap: () => _shareStub(context),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  _HeroButton(
                    icon: AppIcons.heart,
                    label: isFavorite
                        ? 'Favorilerden çıkar'
                        : 'Favorilere ekle',
                    iconColor: isFavorite ? AppColors.textError : null,
                    onTap: onFavoriteTap,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareStub(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paylaşım yakında eklenecek.')),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  static const _size = 44.0;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: _size,
          height: _size,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 22,
            color: iconColor ?? AppColors.iconDefault,
          ),
        ),
      ),
    );
  }
}

/// Marka satırı (Figma: `brand-row` 240:630 — logo döşemesi 48, radius 12).
class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.campaign});

  final Campaign campaign;

  static const _tileSize = 48.0;

  String get _initials => campaign.brand
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((w) => w.characters.first.toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: _tileSize,
          height: _tileSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceSunken,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            _initials,
            style: AppTypography.h5.copyWith(color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: AppSpacing.s4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                campaign.brand,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.h5.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              if (campaign.brandType case final type?) ...[
                // Figma: brand-info gap 2.
                const SizedBox(height: AppSpacing.s1),
                Text(
                  type,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Etiket pili (Figma: `Tag` 144:391 — 26 yüksek, radius 4, `surfaceSunken`).
class _DetailTag extends StatelessWidget {
  const _DetailTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Alt çizgili sekmeler (Figma: `Tabs / Underline` 147:452).
///
/// Flutter'ın `TabBar`/`TabBarView`'ı yerine düz bir seçim listesi: sekme
/// içerikleri farklı yükseklikte ve tek bir `SingleChildScrollView` içinde
/// yaşıyor, `TabBarView` bunun için sınırlı yükseklik ister ve gereksiz
/// karmaşıklık katardı.
class _UnderlineTabs extends StatelessWidget {
  const _UnderlineTabs({
    required this.tabs,
    required this.active,
    required this.onChanged,
  });

  final List<_Tab> tabs;
  final _Tab active;
  final ValueChanged<_Tab> onChanged;

  static String _label(_Tab tab) => switch (tab) {
    _Tab.details => 'Detaylar',
    _Tab.terms => 'Koşullar',
    _Tab.branches => 'Geçerli Şubeler',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final tab in tabs)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(tab),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.s4,
                    ),
                    child: Text(
                      _label(tab),
                      textAlign: TextAlign.center,
                      style: (tab == active
                              ? AppTypography.labelLarge
                              : AppTypography.labelMedium)
                          .copyWith(
                            color: tab == active
                                ? AppColors.textBrand
                                : AppColors.textSecondary,
                          ),
                    ),
                  ),
                  Container(
                    height: 2,
                    color: tab == active
                        ? AppColors.brand
                        : AppColors.borderDefault,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// "Detaylar" sekmesi: geçerlilik bilgisi + "Nasıl kullanılır?" adımları.
class _DetailsTab extends StatelessWidget {
  const _DetailsTab({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (campaign.validity case final validity?)
          BirlikteInfoCard(
            icon: AppIcons.clock,
            message: 'Geçerlilik: $validity',
          ),
        if (campaign.steps.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s6),
          Text('Nasıl kullanılır?', style: AppTypography.h4),
          const SizedBox(height: AppSpacing.s4),
          for (final (i, step) in campaign.steps.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpacing.s4),
            _NumberedStep(number: i + 1, text: step),
          ],
        ],
      ],
    );
  }
}

class _NumberedStep extends StatelessWidget {
  const _NumberedStep({required this.number, required this.text});

  final int number;
  final String text;

  static const _badgeSize = 28.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _badgeSize,
          height: _badgeSize,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.statusInfoSubtle,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textBrand,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s4),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s1),
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// "Koşullar" sekmesi: kimler yararlanabilir + kurallar + iptal notu.
class _TermsTab extends StatelessWidget {
  const _TermsTab({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (campaign.whoQualifies.isNotEmpty) ...[
          Text('Kimler yararlanabilir?', style: AppTypography.h4),
          const SizedBox(height: AppSpacing.s4),
          _BulletList(items: campaign.whoQualifies),
          const SizedBox(height: AppSpacing.s7),
        ],
        if (campaign.rules.isNotEmpty) ...[
          Text('Kampanya koşulları', style: AppTypography.h4),
          const SizedBox(height: AppSpacing.s4),
          _BulletList(items: campaign.rules),
        ],
        if (campaign.cancellationNote case final note?) ...[
          const SizedBox(height: AppSpacing.s5),
          BirlikteInfoCard(message: note),
          const SizedBox(height: AppSpacing.s7),
          Text('İptal ve iade', style: AppTypography.h4),
          const SizedBox(height: AppSpacing.s3),
          Text(
            'Kayıt iptali ve ücret iadesi talepleri kurumun kendi '
            'yönetmeliğine tabidir. İptal edilen kayıtlarda MLPCARE '
            'Birlikte üzerinden oluşturulan kupon otomatik olarak '
            'geçersiz hale gelir.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.s6),
        const Divider(height: 1, color: AppColors.borderDefault),
        const SizedBox(height: AppSpacing.s4),
        Text(
          'Kampanya koşulları ${campaign.brand} tarafından belirlenir. '
          'MLPCARE Birlikte aracı konumundadır; koşullarda değişiklik '
          'yapma hakkı saklıdır.',
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, item) in items.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.iconSubtle,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Text(
                  item,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// "Geçerli Şubeler" sekmesi.
class _BranchesTab extends StatelessWidget {
  const _BranchesTab({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BirlikteInfoCard(
          message: 'Kampanya yalnızca aşağıdaki kampüslerde geçerlidir.',
        ),
        const SizedBox(height: AppSpacing.s7),
        Row(
          children: [
            Text('Kampüsler', style: AppTypography.h4),
            const Spacer(),
            Text(
              '${campaign.branches.length} kampüs',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s4),
        for (final (i, branch) in campaign.branches.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.s4),
          _BranchCard(branch: branch),
        ],
      ],
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({required this.branch});

  final CampaignBranch branch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  branch.name,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Text(
                branch.distanceLabel,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            branch.address,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            branch.hours,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Row(
            children: [
              _BranchActionPill(
                icon: AppIcons.arrowRight,
                label: 'Yol Tarifi',
                onTap: () {},
              ),
              const SizedBox(width: AppSpacing.s3),
              _BranchActionPill(
                icon: AppIcons.phone,
                label: 'Ara',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BranchActionPill extends StatelessWidget {
  const _BranchActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
        decoration: BoxDecoration(
          color: AppColors.surfaceSunken,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.iconDefault),
            const SizedBox(width: AppSpacing.s2),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// İkincil aksiyonlar (Figma: `secondary-actions` 240:688 — Değerlendir,
/// Kaydet, Bildirim; 38 yüksek pill'ler).
///
/// "Değerlendir" ve "Bildirim" için henüz bir akış yok, dokununca bunu
/// söyleyen bir snackbar gösteriyor — buton görünürde tasarımla birebir,
/// arkasındaki özellik ayrı bir iş.
class _SecondaryActions extends StatelessWidget {
  const _SecondaryActions({
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s3,
      runSpacing: AppSpacing.s3,
      children: [
        _ActionPill(
          icon: AppIcons.star,
          label: 'Değerlendir',
          onTap: () => _stub(context, 'Değerlendirme yakında eklenecek.'),
        ),
        _ActionPill(
          icon: AppIcons.heart,
          label: isFavorite ? 'Kaydedildi' : 'Kaydet',
          active: isFavorite,
          onTap: onFavoriteTap,
        ),
        _ActionPill(
          icon: AppIcons.bell,
          label: 'Bildirim',
          onTap: () => _stub(context, 'Bildirim tercihleri yakında eklenecek.'),
        ),
      ],
    );
  }

  void _stub(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.textError : AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
        decoration: BoxDecoration(
          color: AppColors.surfaceSunken,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppSpacing.s2),
            Text(label, style: AppTypography.labelMedium.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
