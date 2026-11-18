import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/birlikte_app_bar.dart';
import '../../home/application/home_providers.dart';
import '../../home/domain/home_models.dart';

/// "Puan kazanma ve kullanma koşulları" (Cüzdanım → "Toplam puanın",
/// puan bedelli bir kampanyada kupon alma ekranı).
///
/// Metin `GET /api/puan/kosullar`'dan geliyor ve YÖNETİMDEN
/// değiştirilebilir — uygulamaya gömülmüyor, bu yüzden burada sabit kodlu
/// hiçbir cümle yok. Sayfa her açıldığında taze çekilsin diye bu sayfaya
/// giden her çağrı yeri (`WalletPage`, kupon oluşturma sheet'i) önce
/// `pointsTermsAsyncProvider`'ı invalidate ediyor.
class PointsTermsPage extends ConsumerWidget {
  const PointsTermsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termsAsync = ref.watch(pointsTermsAsyncProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BirlikteAppBar(onBack: () => context.pop()),
            Expanded(
              child: switch (termsAsync) {
                AsyncData(:final value) => _TermsBody(terms: value),
                AsyncError() => _ErrorRetry(
                  onRetry: () => ref.invalidate(pointsTermsAsyncProvider),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsBody extends StatelessWidget {
  const _TermsBody({required this.terms});

  final PointsTerms terms;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        0,
        AppSpacing.screenH,
        AppSpacing.s8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(terms.baslik, style: AppTypography.h1),
          if (terms.giris.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              terms.giris,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          for (final bolum in terms.bolumler) ...[
            const SizedBox(height: AppSpacing.s7),
            Text(bolum.baslik, style: AppTypography.h4),
            const SizedBox(height: AppSpacing.s4),
            _BulletList(items: bolum.maddeler),
          ],
          if (terms.guncellemeTarihi case final tarih?) ...[
            const SizedBox(height: AppSpacing.s7),
            Text(
              'Son güncelleme: '
              '${DateFormat('d MMMM y', 'tr_TR').format(tarih)}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
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

/// Metin yönetimden geldiği için ağ hatasında uydurma bir yedek
/// göstermiyoruz — kullanıcı gerçek koşulları okumadan devam etmemeli.
class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.onRetry});

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
              'Koşullar yüklenemedi. Bağlantını kontrol edip tekrar dene.',
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
