import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/birlikte_alert_dialog.dart';
import '../../../shared/widgets/birlikte_app_bar.dart';
import '../../../shared/widgets/birlikte_button.dart';
import '../../../shared/widgets/birlikte_chip.dart';
import '../data/interest_repository.dart';
import '../domain/interest_category.dart';

/// İlgi alanı seçimi (Figma: `interest-selection` 3:1829).
///
/// Katalog `GET /api/ilgi-alanlari`'den geliyor (13 sabit kayıt); daha önce
/// seçilmiş olanlar (`secili: true`) başlangıçta işaretli geliyor.
class InterestSelectionPage extends ConsumerStatefulWidget {
  const InterestSelectionPage({super.key});

  @override
  ConsumerState<InterestSelectionPage> createState() =>
      _InterestSelectionPageState();
}

class _InterestSelectionPageState
    extends ConsumerState<InterestSelectionPage> {
  final _selected = <int>{};
  bool _seeded = false;
  bool _saving = false;

  /// Figma `content`: pt 8, başlık ile grid arası 40, chip boşlukları 8.
  static const _contentTop = 8.0;
  static const _afterHeading = AppSpacing.s9;
  static const _chipGap = AppSpacing.s3;
  static const _bottomInset = 28.0;

  bool get _enough => _selected.length >= InterestCategories.minimumSelection;

  void _toggle(int id) => setState(() {
    if (!_selected.remove(id)) _selected.add(id);
  });

  /// Onboarding akışının sonu — yığın temizlenir, geri tuşu buraya dönmez.
  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      await ref.read(interestRepositoryProvider).save(_selected.toList());
      if (!mounted) return;
      context.go(Routes.home);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      await showBirlikteAlert(
        context,
        title: 'Kaydedilemedi',
        message: 'Lütfen tekrar dene.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(interestCatalogProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            BirlikteAppBar(
              onBack: context.canPop() ? context.pop : null,
              onClose: () => context.go(Routes.login),
            ),
            Expanded(
              child: switch (catalogAsync) {
                AsyncError() => _ErrorState(
                  onRetry: () => ref.invalidate(interestCatalogProvider),
                ),
                AsyncData(:final value) => _buildGrid(context, value),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.s5,
                AppSpacing.screenH,
                _bottomInset,
              ),
              child: BirlikteButton(
                label: 'Devam',
                isLoading: _saving,
                onPressed: (_enough && !_saving) ? _finish : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<InterestCategoryItem> catalog) {
    if (!_seeded) {
      _seeded = true;
      _selected.addAll(
        catalog.where((c) => c.secili).map((c) => c.id),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        _contentTop,
        AppSpacing.screenH,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('İlgi alanların neler?', style: AppTypography.display),
          // Figma: heading gap 12.
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Sana özel kampanyalar sunabilmemiz için en az '
            '${InterestCategories.minimumSelection} kategori seç.',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: _afterHeading),
          Wrap(
            spacing: _chipGap,
            runSpacing: _chipGap,
            children: [
              for (final category in catalog)
                BirlikteChip(
                  label: category.ad,
                  selected: _selected.contains(category.id),
                  onTap: () => _toggle(category.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'İlgi alanları yüklenemedi.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            BirlikteButton(
              label: 'Tekrar dene',
              style: BirlikteButtonStyle.secondary,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
