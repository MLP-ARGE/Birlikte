import 'package:flutter/material.dart';

import '../../../../core/birlikte_api/birlikte_api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/birlikte_alert_dialog.dart';
import '../../../../shared/widgets/birlikte_section_header.dart';
import '../../domain/home_models.dart';

/// Başvuru/iptal isteği başarısız olursa (`KAN_GRUBU_UYGUN_DEGIL`,
/// `KAN_GRUBU_YOK`...) gösterilecek, ekrana özel çeviriler.
const _bloodErrorOverrides = {
  'KAN_GRUBU_YOK': 'Başvurabilmek için önce profilinden kan grubunu eklemen '
      'gerekiyor.',
  'KAN_GRUBU_UYGUN_DEGIL': 'Kan grubun bu talebe uygun değil.',
  'KAN_TALEBI_BULUNAMADI': 'Bu talep artık mevcut değil.',
  'KAN_BASVURU_BULUNAMADI': 'İptal edilecek bir başvurun yok.',
};

/// "Kan İhtiyacı Olanlar" bölümü (Figma: `kandas-section` 205:427).
class KandasSection extends StatelessWidget {
  const KandasSection({
    super.key,
    required this.requests,
    this.onSeeAll,
    this.onSupport,
  });

  final List<BloodRequest> requests;
  final VoidCallback? onSeeAll;

  /// Başvuru/iptal isteğini yapar. Hata fırlatırsa (`BirlikteApiException`
  /// ya da ağ hatası) burası yakalayıp kullanıcıya popup gösterir — çağıran
  /// taraf (`HomePage`/`KandasPage`) ayrıca try/catch yazmaz.
  final Future<void> Function(BloodRequest)? onSupport;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BirlikteSectionHeader(
          title: 'Kan İhtiyacı Olanlar',
          // `onSeeAll` yalnızca ana sayfadaki özet kullanımında dolu —
          // Kandaş sekmesi zaten bu listenin TAMAMI, orada kendi kendine
          // yönlendiren bir "Tümünü Gör" anlamsız (bkz. `KandasPage`).
          actionLabel: onSeeAll == null ? null : 'Tümünü Gör',
          onAction: onSeeAll,
        ),
        // Figma: bölüm içi gap 14.
        const SizedBox(height: 14),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            children: [
              // Açık talep yoksa boş kutu çizmek yerine durumu söylüyoruz.
              if (requests.isEmpty) const _EmptyRow(
                text: 'Şu anda açık kan talebi yok.',
              ),
              for (final (i, request) in requests.indexed) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.borderDefault,
                  ),
                _RequestRow(request: request, onSupport: onSupport),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Tüm talepler ilgili hastaneler tarafından doğrulanır.',
          style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request, required this.onSupport});

  final BloodRequest request;
  final Future<void> Function(BloodRequest)? onSupport;

  static const _badgeSize = 44.0;

  Future<void> _handleSupport(BuildContext context) async {
    // Destek ol/geri çek tek dokunuşla hemen gerçekleşiyordu — yanlışlıkla
    // dokunan ya da fikrini değiştiren kullanıcı bir onay adımı olmadan
    // talebi anında gönderip/geri çekiyordu.
    final confirmed = await showBirlikteConfirm(
      context,
      title: request.applied ? 'Başvurunu geri çek' : 'Destek olmak istiyor musun?',
      message: request.applied
          ? 'Bu kan talebine yaptığın başvuruyu geri çekmek istediğine emin misin?'
          : 'Emin misin? Talebiniz ilgili hastaneye iletilecektir.',
      confirmLabel: request.applied ? 'Geri çek' : 'Onayla',
      destructive: request.applied,
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    try {
      await onSupport!(request);
    } on BirlikteApiException catch (e) {
      if (!context.mounted) return;
      await showBirlikteApiErrorAlert(
        context,
        e,
        codeOverrides: _bloodErrorOverrides,
      );
    } catch (e) {
      if (!context.mounted) return;
      await showBirlikteApiErrorAlert(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding
    // Figma: satır iç boşluğu yatay 16, dikey 14; gap 14.
    (
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s5,
        vertical: 14,
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.statusErrorSubtle,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: _badgeSize,
              child: Center(
                child: Text(
                  request.bloodType,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textError,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        request.hospital,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h6.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (request.urgent) ...[
                      const SizedBox(width: AppSpacing.s3),
                      const _UrgentTag(),
                    ],
                  ],
                ),
                // Figma: info gap 3.
                const SizedBox(height: 3),
                Text(
                  request.location?.isNotEmpty ?? false
                      ? request.location!
                      : (request.description ?? ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _SupportButton(
            applied: request.applied,
            onTap: onSupport == null ? null : () => _handleSupport(context),
          ),
        ],
      ),
    );
  }
}

/// "Acil" etiketi (Figma: `urgent` 205:443 — radius 4, `error50` zemin).
class _UrgentTag extends StatelessWidget {
  const _UrgentTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: AppColors.statusErrorSubtle,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            AppIcons.circleAlert,
            size: 12,
            color: AppColors.textError,
          ),
          const SizedBox(width: 3),
          Text(
            'Acil',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textError,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Destek ol" düğmesi (Figma: `support-btn` 205:451 — 34 yüksek, pill,
/// `surfaceSunken` zemin, yatay iç boşluk 14).
class _SupportButton extends StatelessWidget {
  const _SupportButton({required this.applied, required this.onTap});

  /// Kullanıcı bu talebe zaten başvurmuş mu — başvurmuşsa dokununca
  /// başvuru geri çekiliyor (bkz. backend'in mobil önerisi).
  final bool applied;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 34,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: applied
                ? AppColors.statusSuccessSubtle
                : AppColors.surfaceSunken,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            applied ? 'Başvurdun' : 'Destek ol',
            style: AppTypography.buttonSmall.copyWith(
              color: applied ? AppColors.textSuccess : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bölümün boş hâli — veri gelmediğinde kenarlıklı boş bir kutu kalmasın.
class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s5,
        vertical: AppSpacing.s6,
      ),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
