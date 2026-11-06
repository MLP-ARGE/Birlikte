import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Açma/kapama anahtarı.
///
/// Düz `Switch`'te `activeThumbColor`'ı marka rengine ayarlamak, track'le
/// aynı renge düşürüp parçayı (thumb) görünmez kılıyordu ("açıkken beyaz
/// yuvarlak gözükmüyor"). Burada parça her zaman beyaz, yalnızca track
/// açıkken marka rengine boyanıyor — ikisi asla aynı renk olmuyor.
class BirlikteSwitch extends StatelessWidget {
  const BirlikteSwitch({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      thumbColor: const WidgetStatePropertyAll(AppColors.textOnBrand),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.actionPrimary
            : AppColors.borderStrong,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    );
  }
}
