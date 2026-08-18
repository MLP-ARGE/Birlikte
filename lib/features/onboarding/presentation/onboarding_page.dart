import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/birlikte_button.dart';

/// Onboarding (Figma: onboarding-1 3:28, onboarding-2 3:52, onboarding-3 182:636).
///
/// Not: Figma'da üçüncü frame de "onboarding-2" adını taşıyor, ancak sayfa
/// göstergesi üçüncü noktayı aktif gösteriyor — sıralama gösterge esas
/// alınarak kuruldu.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = <_Slide>[
    _Slide(
      headline: 'Dört kurum,\ntek çatı',
      description: 'Medical Park, Liv Hospital, Liv Koleji ve İstinye '
          'Üniversitesi çalışanlarına özel kampanya ve ayrıcalıklar tek '
          'uygulamada.',
      // TODO(assets): kurum logoları 2x2 grid — Figma'dan SVG olarak alınacak.
      visual: _SlideVisual.institutionGrid,
    ),
    _Slide(
      headline: 'Kampanyaları keşfet,\npuan kazan',
      description: 'Sana özel kampanyalardan yararlan, her kullanımda puan '
          'biriktir.',
      visual: _SlideVisual.illustration,
    ),
    _Slide(
      headline: 'Kuponlarınızı Kolayca Kullanın',
      description: 'Kupon kodunuzu oluşturun, mağazada veya online kullanın',
      visual: _SlideVisual.illustration,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  // TODO(login): login ekranı eklenince Routes.login'e yönlenecek.
  void _finish() => context.go(Routes.home);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // "Atla" — sağ üstte tertiary pill
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
                vertical: AppSpacing.s3,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: BirlikteButton(
                  label: 'Atla',
                  onPressed: _finish,
                  style: BirlikteButtonStyle.tertiary,
                  size: BirlikteButtonSize.small,
                  expand: false,
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.s5,
                AppSpacing.screenH,
                AppSpacing.s7,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PageIndicator(count: _slides.length, index: _index),
                  const SizedBox(height: AppSpacing.s6),
                  BirlikteButton(
                    label: 'Devam',
                    onPressed: _next,
                    trailingIcon: Icons.chevron_right,
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

enum _SlideVisual { institutionGrid, illustration }

class _Slide {
  const _Slide({
    required this.headline,
    required this.description,
    required this.visual,
  });

  final String headline;
  final String description;
  final _SlideVisual visual;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: slide.visual == _SlideVisual.institutionGrid
                  ? const _InstitutionGrid()
                  : const _IllustrationPlaceholder(),
            ),
          ),
          Text(slide.headline, style: AppTypography.display),
          const SizedBox(height: AppSpacing.s4),
          Text(
            slide.description,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kurum logolarının 2x2 gridi.
///
/// TODO(assets): logolar Figma'dan SVG olarak indirilip buraya konacak.
/// Marka renkleri Figma'daki kart dolgularından alındı.
class _InstitutionGrid extends StatelessWidget {
  const _InstitutionGrid();

  static const _cards = <(String, Color)>[
    ('liv koleji', Color(0xFF0E86C4)),
    ('Medical Park', Color(0xFFE8262C)),
    ('İSÜ', Color(0xFF1B3050)),
    ('liv HOSPITAL', Color(0xFF0E9BD1)),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.s4,
      crossAxisSpacing: AppSpacing.s4,
      childAspectRatio: 166 / 116,
      children: [
        for (final (name, color) in _cards)
          DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: AppTypography.h5.copyWith(color: AppColors.surface),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// TODO(assets): 3D illüstrasyonlar Figma'dan PNG olarak alınacak.
class _IllustrationPlaceholder extends StatelessWidget {
  const _IllustrationPlaceholder();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceBrand,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: const Center(
          child: Icon(
            Icons.image_outlined,
            size: 48,
            color: AppColors.iconBrand,
          ),
        ),
      ),
    );
  }
}

/// Sayfa göstergesi — aktif olan geniş pill, diğerleri nokta.
class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: EdgeInsets.only(right: i == count - 1 ? 0 : AppSpacing.s3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 8,
              width: i == index ? 28 : 8,
              decoration: BoxDecoration(
                color: i == index ? AppColors.brand : AppColors.borderStrong,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
          ),
      ],
    );
  }
}
