import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/birlikte_app_bar.dart';
import '../../../shared/widgets/birlikte_button.dart';
import '../../../shared/widgets/birlikte_chip.dart';
import '../domain/interest_category.dart';

/// İlgi alanı seçimi (Figma: `interest-selection` 3:1829).
///
/// Figma'da üç kategori (Teknoloji, Seyahat, Sinema) seçili çizilmiş; bu bir
/// örnek durum, uygulama boş başlıyor.
class InterestSelectionPage extends StatefulWidget {
  const InterestSelectionPage({super.key});

  @override
  State<InterestSelectionPage> createState() => _InterestSelectionPageState();
}

class _InterestSelectionPageState extends State<InterestSelectionPage> {
  final _selected = <String>{};

  /// Figma `content`: pt 8, başlık ile grid arası 40, chip boşlukları 8.
  static const _contentTop = 8.0;
  static const _afterHeading = AppSpacing.s9;
  static const _chipGap = AppSpacing.s3;
  static const _bottomInset = 28.0;

  bool get _enough => _selected.length >= InterestCategories.minimumSelection;

  void _toggle(String category) => setState(() {
    if (!_selected.remove(category)) _selected.add(category);
  });

  /// Onboarding akışının sonu — yığın temizlenir, geri tuşu buraya dönmez.
  void _finish() => context.go(Routes.home);

  @override
  Widget build(BuildContext context) {
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  _contentTop,
                  AppSpacing.screenH,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İlgi alanların neler?',
                      style: AppTypography.display,
                    ),
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
                        for (final category in InterestCategories.all)
                          BirlikteChip(
                            label: category,
                            selected: _selected.contains(category),
                            onTap: () => _toggle(category),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
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
                onPressed: _enough ? _finish : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
