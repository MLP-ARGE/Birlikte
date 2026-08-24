import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_typography.dart';
import '../../features/home/domain/home_models.dart';
import 'birlikte_institution_badge.dart';

/// Kampanya kartı (Figma: `Card / Campaign` 149:540 — 260x348, radius 12,
/// beyaz zemin + 1dp `borderDefault`; üstte 151 yüksek görsel, altta 16
/// iç boşluklu gövde).
///
/// Görsel yoksa Figma'nın kendi yer tutucusu kullanılır: marka renginde
/// hediye ikonu. Tasarımdaki örnek fotoğraflar uygulamaya gömülmedi.
class BirlikteCampaignCard extends StatelessWidget {
  const BirlikteCampaignCard({
    super.key,
    required this.campaign,
    this.onTap,
    this.onFavoriteTap,
    this.width = 260,
    this.imageHeight = 151,
    this.isFavorite,
  });

  final Campaign campaign;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final double width;

  /// Figma: karusel kartı 151, Kampanyalar listesindeki tam genişlik kartı
  /// 198.
  final double imageHeight;

  /// Verilmezse `campaign.favorite` seed değeri kullanılır. Favori durumu
  /// canlı bir provider'dan geliyorsa (bkz. `favoriteCampaignIdsProvider`)
  /// çağıran taraf bunu buradan geçirmeli — aksi halde kart, kampanya
  /// nesnesi yeniden oluşturulmadan güncellenmez.
  final bool? isFavorite;

  static const _favoriteSize = 36.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.md),
              ),
              child: SizedBox(
                height: imageHeight,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(child: _Image(url: campaign.imageUrl)),
                    Positioned(
                      top: AppSpacing.s4,
                      right: AppSpacing.s4,
                      child: _FavoriteButton(
                        active: isFavorite ?? campaign.favorite,
                        onTap: onFavoriteTap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (campaign.institution case final institution?)
                    BirlikteInstitutionBadge(
                      institution: institution,
                      height: 16,
                    )
                  else
                    const BirlikteInstitutionBadge.allInstitutions(),
                  const SizedBox(height: 10),
                  Text(
                    campaign.brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    campaign.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h5.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (campaign.pointsCost case final points?) ...[
                    const SizedBox(height: 14),
                    _PointsTag(points: points),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        campaign.discountLabel,
                        style: AppTypography.campaignValue.copyWith(
                          color: AppColors.textBrand,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${campaign.daysLeft} gün kaldı',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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

/// Görsel alanı — Figma'nın yer tutucusu (marka renginde hediye ikonu).
class _Image extends StatelessWidget {
  const _Image({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: AppColors.surfaceBrand,
      child: Center(
        child: Icon(AppIcons.gift, size: 32, color: AppColors.iconBrand),
      ),
    );

    return switch (url) {
      final url? when url.isNotEmpty => CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      ),
      _ => placeholder,
    };
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: active ? 'Favorilerden çıkar' : 'Favorilere ekle',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(
            dimension: BirlikteCampaignCard._favoriteSize,
            child: Center(
              child: Icon(
                AppIcons.heart,
                size: 24,
                color: active ? AppColors.textError : AppColors.iconDefault,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Puan etiketi (Figma: `points-tag` 310:1120 — pill, `info50` zemin).
class _PointsTag extends StatelessWidget {
  const _PointsTag({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Figma: sol 8, sağ 10, dikey 4.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s3,
        AppSpacing.s2,
        10,
        AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: AppColors.statusInfoSubtle,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppIcons.sparkles, size: 13, color: AppColors.iconBrand),
          const SizedBox(width: AppSpacing.s2),
          Text(
            '$points puan',
            style: AppTypography.caption.copyWith(color: AppColors.textBrand),
          ),
        ],
      ),
    );
  }
}
