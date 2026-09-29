import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../home/application/home_providers.dart';
import '../../home/presentation/widgets/kandas_section.dart';

/// Kandaş — açık kan bağışı talepleri.
///
/// Talepler Supabase'den geliyor ve RLS gereği yalnızca `status = 'open'`
/// olanlar görünüyor. Kayıt yoksa ekran boş durumunu gösteriyor; uydurma
/// talep göstermiyoruz.
class KandasPage extends ConsumerWidget {
  const KandasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(bloodRequestsAsyncProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.s5,
            AppSpacing.screenH,
            AppSpacing.s8,
          ),
          children: [
            Text('Kandaş', style: AppTypography.h1),
            const SizedBox(height: AppSpacing.s3),
            Text(
              'MLPCARE hastanelerindeki açık kan bağışı talepleri.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            switch (requestsAsync) {
              AsyncLoading() => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.s7),
                child: Center(child: CircularProgressIndicator()),
              ),
              AsyncError() => const _Empty(
                text: 'Talepler yüklenemedi. Bağlantını kontrol edip '
                    'tekrar dene.',
              ),
              AsyncData(:final value) when value.isEmpty => const _Empty(
                text: 'Şu anda açık kan talebi yok.',
              ),
              // Ana sayfadaki bölümle aynı bileşen: aynı veri iki yerde
              // farklı görünmesin.
              AsyncData(:final value) => KandasSection(requests: value),
            },
            const SizedBox(height: AppSpacing.s6),
            Text(
              'Tüm talepler ilgili hastaneler tarafından doğrulanır.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s7),
      child: Column(
        children: [
          const Icon(AppIcons.droplet, size: 40, color: AppColors.iconSubtle),
          const SizedBox(height: AppSpacing.s4),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
