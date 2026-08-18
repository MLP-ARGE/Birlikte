import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/birlikte_button.dart';

/// Geçici tema doğrulama ekranı.
///
/// !!! GEÇİCİ !!! Figma'daki gerçek `home-page` (199:298) ile değiştirilecek.
/// Şu anki amacı, Figma'dan çıkarılan tokenların cihazda doğru render
/// edildiğini gözle kontrol etmek.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasarım sistemi kontrolü')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        children: [
          _Section(
            title: 'Tipografi',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Display 32/700', style: AppTypography.display),
                Text('Heading H1 28/700', style: AppTypography.h1),
                Text('Heading H3 20/600', style: AppTypography.h3),
                Text('Body Large 16/400', style: AppTypography.bodyLarge),
                Text(
                  'Caption 12/400',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s3),
                Text('BRLK-4F92-KX', style: AppTypography.couponCodeLarge),
                Text(
                  '2.450 puan',
                  style: AppTypography.numericLarge.copyWith(
                    color: AppColors.textBrand,
                  ),
                ),
              ],
            ),
          ),
          _Section(
            title: 'Butonlar',
            child: Column(
              children: [
                for (final (style, label) in const [
                  (BirlikteButtonStyle.primary, 'Primary'),
                  (BirlikteButtonStyle.secondary, 'Secondary'),
                  (BirlikteButtonStyle.tertiary, 'Tertiary'),
                  (BirlikteButtonStyle.ghost, 'Ghost'),
                  (BirlikteButtonStyle.destructive, 'Destructive'),
                ]) ...[
                  BirlikteButton(
                    label: label,
                    onPressed: () {},
                    style: style,
                    trailingIcon: Icons.chevron_right,
                  ),
                  const SizedBox(height: AppSpacing.s3),
                ],
                const BirlikteButton(label: 'Disabled', onPressed: null),
                const SizedBox(height: AppSpacing.s3),
                const BirlikteButton(
                  label: 'Loading',
                  onPressed: null,
                  isLoading: true,
                ),
                const SizedBox(height: AppSpacing.s3),
              ],
            ),
          ),
          const _Section(
            title: 'Renkler',
            child: Wrap(
              spacing: AppSpacing.s3,
              runSpacing: AppSpacing.s3,
              children: [
                _Swatch('brand.600', AppColors.brand),
                _Swatch('brand.700', AppColors.actionPrimaryPressed),
                _Swatch('surface.brand', AppColors.surfaceBrand),
                _Swatch('surface.inverse', AppColors.surfaceInverse),
                _Swatch('success', AppColors.textSuccess),
                _Swatch('warning', AppColors.textWarning),
                _Swatch('error', AppColors.actionDestructive),
                _Swatch('info', AppColors.textInfo),
              ],
            ),
          ),
          _Section(
            title: 'Form',
            child: Column(
              children: [
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Telefon numarası',
                    hintText: '+90 5__ ___ __ __',
                    helperText: 'Kurumda kayıtlı numaranı gir.',
                  ),
                ),
                const SizedBox(height: AppSpacing.s5),
                Row(
                  children: [
                    Switch(value: true, onChanged: (_) {}),
                    const SizedBox(width: AppSpacing.s5),
                    Checkbox(value: true, onChanged: (_) {}),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTypography.overline.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          child,
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 56,
          width: 72,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.borderDefault),
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }
}
