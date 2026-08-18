import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_icons.dart';

/// Üst çubuk.
///
/// Figma iki düzen kullanıyor:
/// * `app-bar` 390x56, yatay iç boşluk 8 — solda geri, sağda kapat
///   (`sms-verification`).
/// * `app-bar` 390x52, yatay iç boşluk 16 — yalnızca solda kapat
///   (`welcome-screen`).
class BirlikteAppBar extends StatelessWidget {
  /// Solda geri, sağda (varsa) kapat.
  const BirlikteAppBar({super.key, this.onBack, this.onClose})
    : height = 56,
      _horizontalPadding = AppSpacing.s3,
      _closeOnLeft = false;

  /// Yalnızca solda kapat düğmesi.
  const BirlikteAppBar.close({super.key, required this.onClose})
    : onBack = null,
      height = 52,
      _horizontalPadding = AppSpacing.s5,
      _closeOnLeft = true;

  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final double height;
  final double _horizontalPadding;
  final bool _closeOnLeft;

  static const _tapSize = 44.0;

  @override
  Widget build(BuildContext context) {
    final close = onClose;

    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
        child: Row(
          children: [
            if (_closeOnLeft && close != null)
              _IconButton(icon: AppIcons.close, label: 'Kapat', onTap: close)
            else if (onBack case final onBack?)
              _IconButton(icon: AppIcons.arrowLeft, label: 'Geri', onTap: onBack)
            else
              const SizedBox(width: _tapSize),
            const Spacer(),
            if (!_closeOnLeft && close != null)
              _IconButton(icon: AppIcons.close, label: 'Kapat', onTap: close),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Tooltip(
        message: label,
        child: SizedBox(
          width: BirlikteAppBar._tapSize,
          height: BirlikteAppBar._tapSize,
          child: Icon(icon, size: AppSize.icon, color: AppColors.iconDefault),
        ),
      ),
    );
  }
}
