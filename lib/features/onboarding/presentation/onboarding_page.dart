import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
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
      visual: _SlideVisual.institutionGrid,
    ),
    _Slide(
      headline: 'Kampanyaları keşfet,\npuan kazan',
      description: 'Sana özel kampanyalardan yararlan, her kullanımda puan '
          'biriktir.',
      visual: _SlideVisual.illustration,
      asset: AppAssets.onboardingCampaigns,
    ),
    _Slide(
      headline: 'Kuponlarınızı Kolayca Kullanın',
      description: 'Kupon kodunuzu oluşturun, mağazada veya online kullanın',
      visual: _SlideVisual.illustration,
      asset: AppAssets.onboardingCoupons,
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

  /// Onboarding'in sonu ve "Atla" — Figma akışında ikisi de login'e gidiyor.
  void _finish() => context.go(Routes.login);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // "Atla" — sağ üstte tertiary pill
            Padding(
              // Figma: top-bar 56 yüksek, btn-skip 36 → dikey 10.
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
                vertical: 10,
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
              // Figma: bottom 136 = pad 16 + dots + 20 + buton 52 + safe-area 20.
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.s5,
                AppSpacing.screenH,
                AppSpacing.s6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PageIndicator(count: _slides.length, index: _index),
                  const SizedBox(height: AppSpacing.s6),
                  BirlikteButton(
                    label: 'Devam',
                    onPressed: _next,
                    trailingIcon: AppIcons.chevronRight,
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
    this.asset,
  });

  final String headline;
  final String description;
  final _SlideVisual visual;

  /// `_SlideVisual.illustration` için görsel yolu.
  final String? asset;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  /// Figma `content` içindeki iki spacer: 20 + 40.
  static const _topGap = 60.0;

  /// Figma `illustration-container` yüksekliği.
  static const _visualH = 370.0;

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    // Figma `content` 390x610: spacer 20 + spacer 40 + görsel 370 + metin 160.
    // Görsel [Flexible] — Column önce metni yerleştirip kalan alanı ona verir.
    // 844 yüksekliğinde tam 370 olur; kısa ekranlarda küçülür, asla taşmaz.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: _topGap),
          Flexible(
            child: SizedBox(
              height: _visualH,
              child: slide.visual == _SlideVisual.institutionGrid
                  ? const _InstitutionGrid()
                  : _Illustration(asset: slide.asset!),
            ),
          ),
          Text(slide.headline, style: AppTypography.display),
          // Figma: text-group gap 12.
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

/// Kurum logolarının 2x2 gridi (Figma: `illustration-container` 182:494).
///
/// Kartlar Figma'dan @3x PNG olarak alındı — arka plan rengi, logo ve radius (14)
/// görselin içinde. Böylece marka logoları birebir tasarımdaki gibi görünüyor.
class _InstitutionGrid extends StatelessWidget {
  const _InstitutionGrid();

  /// Figma'da satır ve kolon boşluğu 10 — 4dp ölçeğinin dışında, o yüzden
  /// [AppSpacing] tokenı yok.
  static const _gap = 10.0;

  static const _cards = <String>[
    AppAssets.brandLivKoleji,
    AppAssets.brandMedicalPark,
    AppAssets.brandIstinyeUniversitesi,
    AppAssets.brandLivHospital,
  ];

  @override
  Widget build(BuildContext context) {
    // Figma: 342x242 (iki satır 116 + 10 boşluk). [FittedBox] dar/kısa
    // ekranlarda oranı bozmadan küçültür.
    return FittedBox(
      child: SizedBox(
        width: 342,
        height: 242,
        child: GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: _gap,
          crossAxisSpacing: _gap,
          childAspectRatio: 166 / 116,
          children: [
            for (final asset in _cards) Image.asset(asset, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }
}

/// Onboarding illüstrasyonu (Figma: `illustration` 342x300).
class _Illustration extends StatelessWidget {
  const _Illustration({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    // Kutuyu doldurur, `contain` oranı korur — Figma'da 342x300 görsel
    // 342x370 konteynerin içinde dikey ortalı duruyor, aynı sonuç.
    return Image.asset(asset, fit: BoxFit.contain);
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
