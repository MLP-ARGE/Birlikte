import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/birlikte_app_bar.dart';
import '../../../shared/widgets/birlikte_button.dart';
import '../../../shared/widgets/birlikte_info_card.dart';

/// Doğrulama başarısız (Figma: `verification-error` 3:1758).
///
/// Kurum kayıtlarında eşleşme bulunamadığında gösterilir.
class VerificationErrorPage extends StatelessWidget {
  const VerificationErrorPage({super.key, this.attemptedValue});

  /// Denenen numara/TCKN — maskeli gösterilir. Bilinmiyorsa kutu gizlenir.
  final String? attemptedValue;

  /// Figma `content`: pt 16; ikon-başlık 24, başlık-kutu 24, kutu-info 12.
  static const _contentTop = AppSpacing.s5;
  static const _iconSize = 72.0;
  static const _bottomInset = 28.0;

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
                    Container(
                      width: _iconSize,
                      height: _iconSize,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.statusWarningSubtle,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        AppIcons.triangleAlert,
                        size: 32,
                        color: AppColors.textWarning,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s7),
                    Text('Seni\nbulamadık', style: AppTypography.display),
                    // Figma: heading gap 12.
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'Girdiğin bilgilerle eşleşen bir çalışan kaydı '
                      'bulunamadı. Bilgilerini kontrol edip tekrar '
                      'deneyebilirsin.',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (attemptedValue case final value?) ...[
                      const SizedBox(height: AppSpacing.s7),
                      _AttemptedValue(
                        value: value,
                        onChange: () => context.go(Routes.login),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.s4),
                    const BirlikteInfoCard(
                      message: 'Sorun devam ederse İnsan Kaynakları '
                          'departmanınla iletişime geçebilirsin.',
                    ),
                  ],
                ),
              ),
            ),
            // Figma: actions VERT gap 12, safe-area 28.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.s5,
                AppSpacing.screenH,
                _bottomInset,
              ),
              child: Column(
                children: [
                  BirlikteButton(
                    label: 'Tekrar dene',
                    onPressed: () => context.go(Routes.login),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  BirlikteButton(
                    label: 'Destek al',
                    style: BirlikteButtonStyle.secondary,
                    // TODO(support): Figma'da `report-issue` (3:2830) ekranı var
                    // ama profil akışına ait; o ekran gelince oraya bağlanacak.
                    // Prototip şimdilik login'e döndürüyor.
                    onPressed: () => context.go(Routes.login),
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

/// Denenen değer kutusu (Figma: `entered-value` 196:302 — radius 12,
/// `surfaceSubtle` zemin, iç boşluk 16/14, gap 12).
class _AttemptedValue extends StatelessWidget {
  const _AttemptedValue({required this.value, required this.onChange});

  final String value;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s5,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(
            AppIcons.phone,
            size: AppSize.iconInButton,
            color: AppColors.iconSubtle,
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Denenen numara',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                // Figma: value gap 2.
                const SizedBox(height: AppSpacing.s1),
                Text(
                  value,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          GestureDetector(
            onTap: onChange,
            child: Text(
              'Değiştir',
              style: AppTypography.buttonSmall.copyWith(
                color: AppColors.textBrand,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
