import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/home_models.dart';

/// "Sana Özel" karuseli (Figma: `promo-carousel` 201:203 — kartlar 280x124,
/// gap 12).
class PromoCarousel extends StatelessWidget {
  const PromoCarousel({
    super.key,
    required this.offers,
    this.onOfferTap,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
  });

  final List<PromoOffer> offers;
  final ValueChanged<PromoOffer>? onOfferTap;

  /// Karusel ekran kenarına kadar kayar; kenar boşluğu buradan verilir.
  final EdgeInsets padding;

  static const _height = 124.0;
  static const _cardWidth = 280.0;
  static const _gap = AppSpacing.s4;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: offers.length,
        separatorBuilder: (_, _) => const SizedBox(width: _gap),
        itemBuilder: (context, i) => _PromoCard(
          offer: offers[i],
          width: _cardWidth,
          onTap: onOfferTap == null ? null : () => onOfferTap!(offers[i]),
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.offer, required this.width, this.onTap});

  final PromoOffer offer;
  final double width;
  final VoidCallback? onTap;

  /// Figma: metin bloğu 170, görsel 110.
  static const _imageWidth = 110.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: width,
          color: AppColors.surfaceSunken,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h6.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      // Figma: metin bloğu gap 4.
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        offer.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            'İncele',
                            style: AppTypography.buttonSmall.copyWith(
                              color: AppColors.textBrand,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s2),
                          const Icon(
                            AppIcons.arrowRight,
                            size: 14,
                            color: AppColors.iconBrand,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: _imageWidth,
                height: double.infinity,
                child: _OfferImage(url: offer.imageUrl),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Görsel yoksa marka zeminde hediye ikonu — kampanya kartındaki yer tutucunun
/// eşi. Tasarımdaki örnek fotoğraflar uygulamaya gömülmedi.
class _OfferImage extends StatelessWidget {
  const _OfferImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: AppColors.surfaceBrand,
      child: Center(
        child: Icon(AppIcons.gift, size: 28, color: AppColors.iconBrand),
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
