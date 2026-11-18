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

  /// Filtre sayfasını açan [_openFilterSheet] build dışından çağrıldığı
  /// için build sırasında buraya yazılıp oradan okunuyor.
  List<CampaignCategoryOption> _categories = const [];

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

  /// Kategori/`sadeceIlgili` filtresi artık sunucuda uygulanıyor
  /// (`campaignsFeedAsyncProvider`) — burada yalnızca arama metni ve
  /// kullanıcının kendi seçtiği sıralama kalıyor. "Önerilen" sunucu
  /// sırasını KORUR, hiç sıralamıyor (backend notu: mobil yeniden
  /// sıralamasın).
  List<Campaign> _filterAndSort(List<Campaign> serverFiltered) {
    final query = _query.trim().toLowerCase();
    var result = query.isEmpty
        ? serverFiltered
        : serverFiltered
              .where(
                (c) =>
                    c.brand.toLowerCase().contains(query) ||
                    c.title.toLowerCase().contains(query),
              )
              .toList();

    if (_sort != _SortOption.recommended) {
      result = [...result]..sort((a, b) {
        switch (_sort) {
          case _SortOption.endingSoon:
            return a.daysLeft.compareTo(b.daysLeft);
          case _SortOption.highestDiscount:
            // Etiketler "%25"/"150 TL"/"Ücretsiz" gibi karışık biçimde;
            // yalnızca yüzdelik olanlar karşılaştırılabilir, diğerleri
            // sona düşer.
            final pa = _percentValue(a.discountLabel);
            final pb = _percentValue(b.discountLabel);
            return pb.compareTo(pa);
          case _SortOption.recommended:
            return 0; // yukarıdaki if ile elenir, buraya düşmez.
        }
      });
    }
    return result;
  }

  static int _percentValue(String label) {
    final match = RegExp(r'^%(\d+)$').firstMatch(label);
    return match == null ? -1 : int.parse(match.group(1)!);
  }

  // Kampanya detayı ayrı bir uçtan (`campaignDetailAsyncProvider`) okunuyor
  // ve autoDispose değil — destek ekibi kuponu iptal ederse kullanıcı aynı
  // kampanyaya tekrar girdiğinde bunu bayat önbellekte değil, taze görmeli.
  void _openCampaign(Campaign campaign) {
    ref.invalidate(campaignDetailAsyncProvider(campaign.id));
    context.push(Routes.campaignDetail(campaign.id));
  }

  @override
  Widget build(BuildContext context) {
    // Home'daki "Tümünü Gör"/"Kampanya" karosu bu sayacı artırıyor — IndexedStack
    // bu sayfayı canlı tuttuğu için filtreler kendiliğinden sıfırlanmaz,
    // aksi halde buradan girenler önceki ziyaretten kalma filtreyle karşılaşır.
    ref.listen(campaignsFilterResetProvider, (previous, next) {
      if (previous != null && previous != next) {
        setState(() {
          _sort = _SortOption.recommended;
          _query = '';
          _searchController.clear();
        });
        ref.read(campaignsFilterProvider.notifier).reset();
      }
    });

    final filter = ref.watch(campaignsFilterProvider);
    final feedAsync = ref.watch(campaignsFeedAsyncProvider);
    final favorites = ref.watch(favoriteSlugsProvider);
    final feed = feedAsync.value;
    _categories = feed?.categories ?? _categories;
    final filtered = _filterAndSort(feed?.campaigns ?? const []);

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
            if (feed != null && feed.selectedInterestCount == 0) ...[
              const SizedBox(height: _sectionGap),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: _SelectInterestsPrompt(
                  onTap: () => context.push(Routes.editInterests),
                ),
              ),
            ],
            const SizedBox(height: _sectionGap),
            _CategoryChips(
              categories: _categories,
              filter: filter,
              showOnlyMine: (feed?.selectedInterestCount ?? 0) > 0,
              onSelectAll: () =>
                  ref.read(campaignsFilterProvider.notifier).selectCategory(null),
              onSelectOnlyMine: () =>
                  ref.read(campaignsFilterProvider.notifier).selectOnlyMine(),
              onSelectCategory: (id) =>
                  ref.read(campaignsFilterProvider.notifier).selectCategory(id),
            ),
            _SortBar(
              count: filtered.length,
              sort: _sort,
              onSortChanged: (s) => setState(() => _sort = s),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: switch (feedAsync) {
                  AsyncError() => _ScrollableCenter(
                    child: _ErrorState(onRetry: _onRefresh),
                  ),
                  _ when filtered.isEmpty && feed != null =>
                    _ScrollableCenter(child: _emptyStateFor(filter)),
                  _ when feed == null => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  _ => ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                        onFavoriteTap: () => toggleCampaignFavorite(
                          context,
                          ref,
                          campaign.id,
                        ),
                      );
                    },
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Arama metni doluyken, hangi kategori seçili olursa olsun aynı "arama
  /// sonucu yok" mesajı — kullanıcı o an metni daraltmaya çalışıyor.
  Widget _emptyStateFor(CampaignsFilter filter) {
    if (_query.trim().isNotEmpty) return const _NoResults();
    if (filter.sadeceIlgili) return const _EmptyOnlyMine();
    if (filter.ilgiAlaniId case final id?) {
      final name = _categories
          .cast<CampaignCategoryOption?>()
          .firstWhere((c) => c?.id == id, orElse: () => null)
          ?.ad;
      if (name != null) return _EmptyCategory(categoryName: name);
    }
    return const _NoResults();
  }

  Future<void> _onRefresh() => Future.wait([
    ref.refresh(campaignsAsyncProvider.future),
    ref.refresh(campaignsFeedAsyncProvider.future),
  ]);

  void _openFilterSheet() {
    final filter = ref.read(campaignsFilterProvider);
    final feed = ref.read(campaignsFeedAsyncProvider).value;
    showModalBottomSheet<void>(
      context: context,
      // Bulgu UI-003: sheet kök navigator'da açılmalı.
      //
      // Sekmeler StatefulShellRoute.indexedStack ile kuruluyor ve her dalın
      // kendi Navigator'ı var. Varsayılan davranışta sheet o dalın içinde
      // açılıyor, dolayısıyla alt navigasyon barı sheet'in ÜSTÜNDE kalıyor:
      // karartma barı kapsamıyor ve sheet içeriği barla kesişiyor.
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      // Kategori sayısı modalın varsayılan yüksekliğini aşabiliyor;
      // isScrollControlled olmadan bu, içerik kırpılmadan taşma uyarısına
      // (sarı-siyah şerit) yol açıyordu.
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) => _CategoryFilterSheet(
        categories: _categories,
        filter: filter,
        showOnlyMine: (feed?.selectedInterestCount ?? 0) > 0,
        onSelectAll: () {
          ref.read(campaignsFilterProvider.notifier).selectCategory(null);
          Navigator.pop(sheetContext);
        },
        onSelectOnlyMine: () {
          ref.read(campaignsFilterProvider.notifier).selectOnlyMine();
          Navigator.pop(sheetContext);
        },
        onSelectCategory: (id) {
          ref.read(campaignsFilterProvider.notifier).selectCategory(id);
          Navigator.pop(sheetContext);
        },
      ),
    );
  }
}

/// Boş/hata durumlarını da bir `Scrollable` içine sarar — aksi halde
/// `RefreshIndicator` sürüklemeyi algılayamıyor (içinde kaydırılabilir bir
/// şey yok), aşağı çekip yenileme çalışmaz.
class _ScrollableCenter extends StatelessWidget {
  const _ScrollableCenter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              AppIcons.circleAlert,
              size: 48,
              color: AppColors.iconSubtle,
            ),
            const SizedBox(height: AppSpacing.s5),
            Text(
              'Kampanyalar yüklenemedi',
              style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Bağlantını kontrol edip tekrar dene.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            TextButton(onPressed: onRetry, child: const Text('Tekrar dene')),
          ],
        ),
      ),
    );
  }
}

/// `seciliIlgiAlaniSayisi == 0` — backend notu: "ilgi alanlarını seç"
/// yönlendirmesi gösterin.
class _SelectInterestsPrompt extends StatelessWidget {
  const _SelectInterestsPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.star, size: 20, color: AppColors.iconDefault),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'İlgi alanlarını seç, sana uygun kampanyalar öne çıksın.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          TextButton(onPressed: onTap, child: const Text('Seç')),
        ],
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
                          // Bulgu UI-004: `border` yalnızca yedek değer;
                          // temadaki focusedBorder odaklanınca onu ezip
                          // sarmalayıcının İÇİNE ikinci bir dikdörtgen
                          // çiziyordu. Her durumu açıkça kapatıyoruz —
                          // alanın çerçevesi dıştaki pill'in kendisi.
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
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
  const _CategoryChips({
    required this.categories,
    required this.filter,
    required this.showOnlyMine,
    required this.onSelectAll,
    required this.onSelectOnlyMine,
    required this.onSelectCategory,
  });

  /// İlgi alanı kataloğunun TAMAMI — `GET /api/kampanyalar`'ın üst seviye
  /// `ilgiAlanlari` dizisinden (kampanyası olmayan bir kategori de sekme
  /// olarak görünür, seçilince kendi boş durumunu anlatır).
  final List<CampaignCategoryOption> categories;
  final CampaignsFilter filter;

  /// Kullanıcı en az bir ilgi alanı seçtiyse "İlgi Alanlarım" çipi gösterilir.
  final bool showOnlyMine;

  final VoidCallback onSelectAll;
  final VoidCallback onSelectOnlyMine;
  final ValueChanged<int> onSelectCategory;

  static const _height = 48.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        // Bulgu UI-005: chip'ler sağ kenarda kesiliyor ve kaydırılabilir
        // oldukları belli olmuyor. Sağdaki dolguyu küçültüyoruz ki son chip
        // kısmen görünsün — kesilmiş değil, devam ediyor izlenimi versin.
        padding: const EdgeInsets.only(
          left: AppSpacing.screenH,
          right: AppSpacing.s4,
        ),
        children: [
          BirlikteChip(
            label: 'Tümü',
            selected: filter.ilgiAlaniId == null && !filter.sadeceIlgili,
            onTap: onSelectAll,
          ),
          if (showOnlyMine) ...[
            const SizedBox(width: AppSpacing.s3),
            BirlikteChip(
              label: 'İlgi Alanlarım',
              selected: filter.sadeceIlgili,
              onTap: onSelectOnlyMine,
            ),
          ],
          for (final category in categories) ...[
            const SizedBox(width: AppSpacing.s3),
            BirlikteChip(
              label: category.ad,
              selected: filter.ilgiAlaniId == category.id,
              marked: category.secili,
              onTap: () => onSelectCategory(category.id),
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

/// Seçili kategoride henüz kampanya yoksa — genel "sonuç bulunamadı"
/// yerine hangi kategoride olduğunu söyleyen özel bir boş durum.
class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory({required this.categoryName});

  final String categoryName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              AppIcons.ticketPercent,
              size: 48,
              color: AppColors.iconSubtle,
            ),
            const SizedBox(height: AppSpacing.s5),
            Text(
              '$categoryName kategorisinde kampanya yok',
              textAlign: TextAlign.center,
              style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Bu kategoride şu anda aktif bir kampanya bulunmuyor, '
              'daha sonra tekrar kontrol et.',
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

/// "İlgi Alanlarım" (`sadeceIlgili=true`) seçiliyken eşleşen kampanya yoksa.
class _EmptyOnlyMine extends StatelessWidget {
  const _EmptyOnlyMine();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.star, size: 48, color: AppColors.iconSubtle),
            const SizedBox(height: AppSpacing.s5),
            Text(
              'İlgi alanlarına uygun kampanya yok',
              textAlign: TextAlign.center,
              style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Seçtiğin ilgi alanlarıyla eşleşen aktif bir kampanya '
              'bulunmuyor; "Tümü" sekmesinden diğer kampanyalara göz '
              'atabilirsin.',
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
    required this.categories,
    required this.filter,
    required this.showOnlyMine,
    required this.onSelectAll,
    required this.onSelectOnlyMine,
    required this.onSelectCategory,
  });

  /// Yatay çubukla aynı küme — iki yerde farklı liste göstermek kafa karıştırır.
  final List<CampaignCategoryOption> categories;
  final CampaignsFilter filter;
  final bool showOnlyMine;
  final VoidCallback onSelectAll;
  final VoidCallback onSelectOnlyMine;
  final ValueChanged<int> onSelectCategory;

  @override
  Widget build(BuildContext context) {
    // Kategori sayısı, sabit yükseklikli modalın varsayılan alanını
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
                selected: filter.ilgiAlaniId == null && !filter.sadeceIlgili,
                onTap: onSelectAll,
              ),
              if (showOnlyMine)
                _FilterRow(
                  label: 'İlgi Alanlarım',
                  selected: filter.sadeceIlgili,
                  onTap: onSelectOnlyMine,
                ),
              for (final category in categories)
                _FilterRow(
                  label: category.ad,
                  selected: filter.ilgiAlaniId == category.id,
                  marked: category.secili,
                  onTap: () => onSelectCategory(category.id),
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
    this.marked = false,
  });

  final String label;
  final bool selected;
  final bool marked;
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
              child: Row(
                children: [
                  Text(
                    label,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (marked && !selected) ...[
                    const SizedBox(width: AppSpacing.s2),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(width: 6, height: 6),
                    ),
                  ],
                ],
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
