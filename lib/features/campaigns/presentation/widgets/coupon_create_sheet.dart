import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/birlikte_api/birlikte_api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/birlikte_alert_dialog.dart';
import '../../../../shared/widgets/birlikte_button.dart';
import '../../../../shared/widgets/birlikte_info_card.dart';
import '../../../home/domain/home_models.dart';
import '../../data/campaign_repository.dart';

/// Kupon oluşturma onayı (Figma: `coupon-create-confirm_Main` 3:800).
///
/// Kupon kodu `POST /api/kampanyalar/{guid}/kupon` ile sunucuda üretilir;
/// kontenjan ve puan bakiyesi kuralları orada uygulanıyor.
Future<void> showCouponCreateSheet(BuildContext context, Campaign campaign) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (sheetContext) => _CouponCreateSheet(campaign: campaign),
  );
}

/// Kuponu zaten alınmış bir kampanya için kodu tekrar gösterir.
Future<void> showExistingCouponDialog(
  BuildContext context,
  CampaignCoupon coupon,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _CouponSuccessDialog(coupon: coupon),
  );
}

class _CouponCreateSheet extends ConsumerStatefulWidget {
  const _CouponCreateSheet({required this.campaign});

  final Campaign campaign;

  @override
  ConsumerState<_CouponCreateSheet> createState() => _CouponCreateSheetState();
}

class _CouponCreateSheetState extends ConsumerState<_CouponCreateSheet> {
  bool _creating = false;

  Campaign get campaign => widget.campaign;

  static const _grabberTop = AppSpacing.s3;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          0,
          AppSpacing.screenH,
          AppSpacing.s5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: _grabberTop),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s5),
            Text('Kuponu oluştur', style: AppTypography.h3),
            // Figma: başlık-açıklama gap 6.
            const SizedBox(height: 6),
            Text(
              campaign.puanBedeli > 0
                  ? 'Kupon oluşturduğunda ${campaign.puanBedeli} puan '
                      'bakiyenden düşülür ve kod hemen üretilir.'
                  : 'Kupon oluşturduğunda kod hemen üretilir ve süre işlemeye '
                      'başlar.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            _CampaignSummary(campaign: campaign),
            const SizedBox(height: AppSpacing.s6),
            Text(
              'KUPON KURALLARI',
              style: AppTypography.overline.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            const _RuleRow(
              icon: AppIcons.ticket,
              title: 'Tek kullanımlıktır',
              detail: 'Oluşturduktan sonra yalnızca bir kez kullanabilirsin.',
            ),
            const SizedBox(height: AppSpacing.s4),
            const _RuleRow(
              icon: AppIcons.clock,
              title: '72 saat geçerlidir',
              detail: 'Kod oluşturulduktan 72 saat sonra kullanılamaz.',
            ),
            const SizedBox(height: AppSpacing.s4),
            _RuleRow(
              icon: AppIcons.circleCheck,
              title: 'Online başvuruda geçerli',
              detail: '${campaign.brand} sisteminde kullanılır.',
            ),
            const SizedBox(height: AppSpacing.s5),
            const BirlikteInfoCard(
              message: 'Kupon oluşturulduktan sonra iptal edilemez ve '
                  'süresi dolarsa yeniden oluşturulamaz.',
            ),
            const SizedBox(height: AppSpacing.s6),
            BirlikteButton(
              label: 'Kuponu oluştur',
              isLoading: _creating,
              onPressed: _creating ? null : _confirm,
            ),
            const SizedBox(height: AppSpacing.s3),
            BirlikteButton(
              label: 'Vazgeç',
              style: BirlikteButtonStyle.ghost,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    setState(() => _creating = true);

    try {
      final coupon = await ref
          .read(campaignRepositoryProvider)
          .createCoupon(campaign.id);

      if (!mounted) return;
      Navigator.pop(context);
      unawaited(showExistingCouponDialog(context, coupon));
    } on BirlikteApiException catch (e) {
      if (!mounted) return;
      await showBirlikteAlert(
        context,
        title: 'Kupon oluşturulamadı',
        message: _messageFor(e),
      );
    } catch (_) {
      if (!mounted) return;
      await showBirlikteAlert(
        context,
        title: 'Kupon oluşturulamadı',
        message: 'Lütfen tekrar dene.',
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  static String _messageFor(BirlikteApiException e) {
    switch (e.code) {
      case 'KUPON_YOK':
        return 'Bu kampanya için kupon tanımlı değil.';
      case 'KAMPANYA_BULUNAMADI':
        return 'Kampanya bulunamadı.';
      case 'KOTA_DOLDU':
        return 'Bu kampanyanın kontenjanı doldu.';
      case 'YETERSIZ_PUAN':
        final veri = e.veri;
        final bakiye = veri?['bakiye'];
        final gereken = veri?['gereken'];
        return bakiye != null && gereken != null
            ? 'Puanın yetersiz (bakiye: $bakiye, gereken: $gereken).'
            : 'Puanın yetersiz.';
      default:
        return e.message.isNotEmpty
            ? e.message
            : 'Kupon oluşturulamadı. Lütfen tekrar dene.';
    }
  }
}

class _CampaignSummary extends StatelessWidget {
  const _CampaignSummary({required this.campaign});

  final Campaign campaign;

  static const _tileSize = 52.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: _tileSize,
            height: _tileSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceSunken,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(AppIcons.gift, color: AppColors.iconBrand),
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign.brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  campaign.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.iconDefault),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.s1),
              Text(
                detail,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Kupon başarıyla oluşturulunca (ya da daha önce alınmış bir kuponu tekrar
/// açarken) gösterilen kod (Figma: `coupon-success_Main` 3:834).
class _CouponSuccessDialog extends StatelessWidget {
  const _CouponSuccessDialog({required this.coupon});

  final CampaignCoupon coupon;

  @override
  Widget build(BuildContext context) {
    // Sunucu geçerlilik tarihini vermediyse (eski yanıt şekli) 72 saatlik
    // kural metniyle tutarlı bir tahmini gösteriyoruz.
    final expiry = coupon.expiresAt ??
        DateTime.now().add(const Duration(hours: 72));
    final expiryLabel = DateFormat('d MMMM, HH:mm', 'tr_TR').format(expiry);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.statusSuccessSubtle,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.s4),
                child: Icon(
                  AppIcons.circleCheck,
                  size: 32,
                  color: AppColors.textSuccess,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s5),
            Text(
              coupon.isExpired ? 'Kuponun' : 'Kuponun hazır',
              style: AppTypography.h4,
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              coupon.isExpired
                  ? 'Süresi doldu.'
                  : '$expiryLabel\'e kadar geçerli.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s5),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s5),
              decoration: BoxDecoration(
                color: AppColors.surfaceSunken,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Text(coupon.code, style: AppTypography.couponCodeLarge),
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            BirlikteButton(
              label: 'Tamam',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
