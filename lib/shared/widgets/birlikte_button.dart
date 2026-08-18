import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';

/// Buton stilleri (Figma: 04 — Components / Button).
enum BirlikteButtonStyle { primary, secondary, tertiary, ghost, destructive }

/// Buton boyutları — yükseklik 52 / 48 / 40.
enum BirlikteButtonSize { large, medium, small }

/// Tasarım sistemindeki Button component'inin Flutter karşılığı.
///
/// Figma'daki 60 varyantın (5 stil × 3 boyut × 4 durum) tamamını karşılar.
/// Tüm varyantlar pill biçimlidir (radius.full).
///
/// `isLoading` durumunda buton genişliğini korur ve etiket yerine spinner
/// gösterir; basma engellenir.
class BirlikteButton extends StatelessWidget {
  const BirlikteButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.style = BirlikteButtonStyle.primary,
    this.size = BirlikteButtonSize.large,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;

  /// null ise buton devre dışı görünür.
  final VoidCallback? onPressed;
  final BirlikteButtonStyle style;
  final BirlikteButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;

  /// true ise satır genişliğini kaplar (ekran altı CTA'ları böyle).
  final bool expand;

  bool get _enabled => onPressed != null && !isLoading;

  double get _height => switch (size) {
        BirlikteButtonSize.large => AppSize.buttonLarge,
        BirlikteButtonSize.medium => AppSize.buttonMedium,
        BirlikteButtonSize.small => AppSize.buttonSmall,
      };

  double get _padH => switch (size) {
        BirlikteButtonSize.large => AppSize.buttonPadHLarge,
        BirlikteButtonSize.medium => AppSize.buttonPadHMedium,
        BirlikteButtonSize.small => AppSize.buttonPadHSmall,
      };

  double get _gap => size == BirlikteButtonSize.small
      ? AppSize.buttonGapSmall
      : AppSize.buttonGapLarge;

  TextStyle get _textStyle => switch (size) {
        BirlikteButtonSize.large => AppTypography.buttonLarge,
        BirlikteButtonSize.medium => AppTypography.buttonMedium,
        BirlikteButtonSize.small => AppTypography.buttonSmall,
      };

  /// Figma varyant matrisindeki dolgu rengi.
  Color? _fill(Set<WidgetState> states) {
    final pressed = states.contains(WidgetState.pressed);
    if (!_enabled) {
      return switch (style) {
        BirlikteButtonStyle.secondary => AppColors.surface,
        BirlikteButtonStyle.ghost => null,
        _ => AppColors.actionDisabled,
      };
    }
    return switch (style) {
      BirlikteButtonStyle.primary =>
        pressed ? AppColors.actionPrimaryPressed : AppColors.actionPrimary,
      BirlikteButtonStyle.secondary =>
        pressed ? AppColors.surfaceSunken : AppColors.surface,
      BirlikteButtonStyle.tertiary => AppColors.surfaceSunken,
      BirlikteButtonStyle.ghost => pressed ? AppColors.surfaceSunken : null,
      BirlikteButtonStyle.destructive => pressed
          ? AppColors.actionDestructivePressed
          : AppColors.actionDestructive,
    };
  }

  Color get _foreground {
    if (!_enabled) return AppColors.textDisabled;
    return switch (style) {
      BirlikteButtonStyle.primary ||
      BirlikteButtonStyle.destructive =>
        AppColors.textOnBrand,
      _ => AppColors.textPrimary,
    };
  }

  BorderSide get _border {
    if (style != BirlikteButtonStyle.secondary) return BorderSide.none;
    return BorderSide(
      color: _enabled ? AppColors.borderStrong : AppColors.borderDefault,
      width: 1.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            height: AppSize.iconInButton,
            width: AppSize.iconInButton,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(_foreground),
            ),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: AppSize.iconInButton),
                SizedBox(width: _gap),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              if (trailingIcon != null) ...[
                SizedBox(width: _gap),
                Icon(trailingIcon, size: AppSize.iconInButton),
              ],
            ],
          );

    final button = SizedBox(
      height: _height,
      width: expand ? double.infinity : null,
      child: TextButton(
        onPressed: _enabled ? onPressed : null,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(_fill),
          foregroundColor: WidgetStatePropertyAll(_foreground),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          side: WidgetStatePropertyAll(_border),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: _padH),
          ),
          minimumSize: WidgetStatePropertyAll(Size(0, _height)),
          textStyle: WidgetStatePropertyAll(_textStyle),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          elevation: const WidgetStatePropertyAll(0),
          splashFactory: NoSplash.splashFactory,
        ),
        child: child,
      ),
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: label,
      child: ExcludeSemantics(child: button),
    );
  }
}
