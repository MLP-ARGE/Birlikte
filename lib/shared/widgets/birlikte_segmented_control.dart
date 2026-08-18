import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_typography.dart';

/// Segment tanımı — [value] seçim anahtarı, [label] görünen metin.
class BirlikteSegment<T> {
  const BirlikteSegment({required this.value, required this.label});

  final T value;
  final String label;
}

/// Segmented control (Figma: `Segmented Control` 147:419, 2 ve 3 segment).
///
/// Ölçüler Figma'dan: kapsayıcı 44 yüksek, radius 10, dolgu `surfaceSunken`,
/// iç boşluk 3, segmentler arası 2; segment 38 yüksek, radius 8. Aktif segment
/// beyaz zemin + `AppElevation.level1`.
///
/// Tasarımdan bilinçli sapma: Figma aktif etikete 15/500, pasife 14/500 veriyor.
/// Seçim değiştikçe metin boyutu zıplayacağı için ikisinde de 15/500
/// ([AppTypography.labelLarge]) kullanıldı — tasarım ekibine sorulmalı.
class BirlikteSegmentedControl<T> extends StatelessWidget {
  const BirlikteSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
  }) : assert(segments.length >= 2, 'en az iki segment gerekir');

  final List<BirlikteSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;

  static const _height = 44.0;
  static const _pad = 3.0;
  static const _gap = 2.0;
  static const _segmentHeight = 38.0;
  static const _radius = 10.0;
  static const _segmentRadius = 8.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      padding: const EdgeInsets.all(_pad),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: Row(
        children: [
          for (final (i, segment) in segments.indexed) ...[
            if (i > 0) const SizedBox(width: _gap),
            Expanded(child: _Segment(
              label: segment.label,
              selected: segment.value == value,
              onTap: () => onChanged(segment.value),
            )),
          ],
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: selected ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: BirlikteSegmentedControl._segmentHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(
              BirlikteSegmentedControl._segmentRadius,
            ),
            boxShadow: selected ? AppElevation.level1 : AppElevation.level0,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelLarge.copyWith(
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
