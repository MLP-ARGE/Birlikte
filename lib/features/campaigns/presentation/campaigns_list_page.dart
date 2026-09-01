import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/birlikte_campaign_card.dart';
import '../../../shared/widgets/birlikte_chip.dart';
import '../../home/application/home_providers.dart';
import '../../home/domain/home_models.dart';

/// Sıralama ölçütü (Figma: `sort-btn` 204:314 — tek örnek "Önerilen" çizilmiş,
/// diğer seçenekler prototipte yok; en yaygın kalıp izlendi).
enum _SortOption {
  recommended('Önerilen'),
  endingSoon('Süresi yaklaşan'),
  highestDiscount('En yüksek indirim');

  const _SortOption(this.label);

  final String label;
}

/// Kampanyalar listesi (Figma: `campaigns-list` 3:525).
class CampaignsListPage extends ConsumerStatefulWidget {
  const CampaignsListPage({super.key});

  @override
  ConsumerState<CampaignsListPage> createState() => _CampaignsListPageState();
}

class _CampaignsListPageState extends ConsumerState<CampaignsListPage> {
  final _searchController = TextEditingController();
  CampaignCategory? _category;
  _SortOption _sort = _SortOption.recommended;
  String _query = '';

  /// Figma `header`: pt görünmüyor (status-bar ayrı), başlık-arama gap 14.
  static const _headerTop = AppSpacing.s5;
  static const _afterTitle = AppSpacing.s4;
  static const _sectionGap = AppSpacing.s3;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Campaign> _filterAndSort(List<Campaign> all) {
    final query = _query.trim().toLowerCase();
    var result = all.where((c) {
      final matchesCategory = _category == null || c.category == _category;
      final matchesQuery =
          query.isEmpty ||
          c.brand.toLowerCase().contains(query) ||
          c.title.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    result.sort((a, b) {
      switch (_sort) {
        case _SortOption.recommended:
          return 0;
        case _SortOption.endingSoon:
          return a.daysLeft.compareTo(b.daysLeft);
        case _SortOption.highestDiscount:
          // Etiketler "%25"/"150 TL"/"Ücretsiz" gibi karışık biçimde; yalnızca
          // yüzdelik olanlar karşılaştırılabilir, diğerleri sona düşer.
          final pa = _percentValue(a.discountLabel);
          final pb = _percentValue(b.discountLabel);
          return pb.compareTo(pa);
      }
    });
    return result;
  }

  static int _percentValue(String label) {
    final match = RegExp(r'^%(\d+)$').firstMatch(label);
    return match == null ? -1 : int.parse(match.group(1)!);
  }

  void _openCampaign(Campaign campaign) =>
      context.push(Routes.campaignDetail(campaign.id));

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(campaignsProvider);
    final favorites = ref.watch(favoriteSlugsProvider);
    final filtered = _filterAndSort(all);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                _headerTop,
                AppSpacing.screenH,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kampanyalar', style: AppTypography.h1),
                  const SizedBox(height: _afterTitle),
                  _SearchRow(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    onFilterTap: _openFilterSheet,
                  ),
                ],
              ),
            ),
            const SizedBox(height: _sectionGap),
            _CategoryChips(
              selected: _category,
              onSelected: (c) => setState(() => _category = c),
            ),
            _SortBar(
              count: filtered.length,
              sort: _sort,
              onSortChanged: (s) => setState(() => _sort = s),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const _NoResults()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenH,
                        0,
                        AppSpacing.screenH,
                        AppSpacing.s8,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.s5),
                      itemBuilder: (context, i) {
                        final campaign = filtered[i];
                        return BirlikteCampaignCard(
                          campaign: campaign,
                          width: double.infinity,
                          imageHeight: 198,
                          isFavorite: favorites.contains(campaign.id),
                          onTap: () => _openCampaign(campaign),
                          onFavoriteTap: () => ref
                              .read(favoriteCampaignIdsProvider.notifier)
                              .toggle(campaign.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      // Kategori sayısı (Tümü + 8) modalın varsayılan yüksekliğini aşıyor;
      // isScrollControlled olmadan bu, içerik kırpılmadan taşma uyarısına
      // (sarı-siyah şerit) yol açıyordu.
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) => _CategoryFilterSheet(
        selected: _category,
        onSelected: (c) {
          setState(() => _category = c);
          Navigator.pop(sheetContext);
        },
      ),
    );
  }
}

/// Arama alanı + filtre düğmesi (Figma: `search-row` 204:279).
class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.controller,
    required this.onChanged,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;

  static const _height = 48.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: Row(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceSunken,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                child: Row(
                  children: [
                    const Icon(
                      AppIcons.search,
                      size: 20,
                      color: AppColors.iconSubtle,
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        onChanged: onChanged,
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          hintText: 'Kampanya veya marka ara',
                          hintStyle: AppTypography.labelLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Semantics(
            button: true,
            label: 'Filtrele',
            child: GestureDetector(
              onTap: onFilterTap,
              child: Container(
                width: _height,
                height: _height,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSunken,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: const Icon(
                  AppIcons.filter,
                  size: 20,
                  color: AppColors.iconDefault,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kategori filtre çipleri (Figma: `chips-row` 445:10135).
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelected});

  final CampaignCategory? selected;
  final ValueChanged<CampaignCategory?> onSelected;

  static const _height = 48.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        children: [
          BirlikteChip(
            label: 'Tümü',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final category in CampaignCategory.values) ...[
            const SizedBox(width: AppSpacing.s3),
            BirlikteChip(
              label: category.label,
              selected: selected == category,
              onTap: () => onSelected(category),
            ),
          ],
        ],
      ),
    );
  }
}

/// Aktif kampanya sayısı + sıralama (Figma: `sort-bar` 204:311).
class _SortBar extends StatelessWidget {
  const _SortBar({
    required this.count,
    required this.sort,
    required this.onSortChanged,
  });

  final int count;
  final _SortOption sort;
  final ValueChanged<_SortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.s3,
        AppSpacing.screenH,
        AppSpacing.s3,
      ),
      child: Row(
        children: [
          Text(
            '$count aktif kampanya',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          PopupMenuButton<_SortOption>(
            initialValue: sort,
            onSelected: onSortChanged,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            itemBuilder: (context) => [
              for (final option in _SortOption.values)
                PopupMenuItem(value: option, child: Text(option.label)),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sort.label,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.s2),
                const Icon(
                  AppIcons.chevronDown,
                  size: 16,
                  color: AppColors.iconDefault,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Arama/filtre sonuç vermediğinde (Figma: `search-no-results` 3:3076,
/// `filter-no-results` 3:3143 — tek, sade bir mesajla birleştirildi).
class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              AppIcons.searchOff,
              size: 48,
              color: AppColors.iconSubtle,
            ),
            const SizedBox(height: AppSpacing.s5),
            Text(
              'Sonuç bulunamadı',
              style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Farklı bir arama terimi veya kategori dene.',
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

/// Filtre düğmesinin açtığı sayfa alt sayfası (Figma: `campaign-filter`
/// 3:620 sadeleştirildi — kategori seçimi zaten çip satırında var, burada
/// ek olarak sunulmuyor; bu sayfa aynı seçimi büyük dokunma hedefli bir
/// listede tekrarlıyor, mobilde tek elle kullanım için).
class _CategoryFilterSheet extends StatelessWidget {
  const _CategoryFilterSheet({
    required this.selected,
    required this.onSelected,
  });

  final CampaignCategory? selected;
  final ValueChanged<CampaignCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    // Tümü + 8 kategori, sabit yükseklikli modalın varsayılan alanını
    // aşabiliyor (kısa ekranlarda, büyük yazı tipi ölçeğinde). İçerik
    // sığdığında olduğu boyutta durur, sığmadığında kendi içinde kaydırır —
    // dışarıdaki modal büyümez.
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.s5,
            AppSpacing.screenH,
            AppSpacing.s5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kategori', style: AppTypography.h4),
              const SizedBox(height: AppSpacing.s4),
              _FilterRow(
                label: 'Tümü',
                selected: selected == null,
                onTap: () => onSelected(null),
              ),
              for (final category in CampaignCategory.values)
                _FilterRow(
                  label: category.label,
                  selected: selected == category,
                  onTap: () => onSelected(category),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (selected)
              const Icon(AppIcons.check, size: 20, color: AppColors.brand),
          ],
        ),
      ),
    );
  }
}
