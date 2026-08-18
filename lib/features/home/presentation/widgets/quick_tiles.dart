import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';

/// Hızlı erişim döşemesi tanımı.
class QuickTile {
  const QuickTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

/// Hızlı erişim satırı (Figma: `quick-tiles` 201:146 — 4 döşeme, gap 10,
/// her biri 76 yüksek, radius full, `surfaceSubtle` zemin, ikon 26,
/// üst iç boşluk 14 / alt 12, ikon-etiket arası 8).
class QuickTiles extends StatelessWidget {
  const QuickTiles({super.key, required this.tiles});

  final List<QuickTile> tiles;

  static const _height = 76.0;
  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: Row(
        children: [
          for (final (i, tile) in tiles.indexed) ...[
            if (i > 0) const SizedBox(width: _gap),
            Expanded(child: _Tile(tile: tile)),
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.tile});

  final QuickTile tile;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: tile.onTap,
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 14, bottom: AppSpacing.s4),
            child: Column(
              children: [
                Icon(tile.icon, size: 26, color: AppColors.iconDefault),
                const SizedBox(height: AppSpacing.s3),
                Text(
                  tile.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
