import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';

/// Metin girişi (Figma: `Input` 143:268).
///
/// Ölçüler Figma'dan: etiket satırı gap 4, alan 48 yüksek + radius 8 +
/// `surfaceSunken` dolgu + yatay 12 iç boşluk, yardımcı satır gap 4.
///
/// Not: Figma'da Input'un yalnızca **varsayılan** durumu çizilmiş. Odak ve hata
/// görünümleri semantic tokenlardan türetildi ([AppColors.borderFocus],
/// [AppColors.borderError]) — tasarım ekibi bu durumları çizince gözden
/// geçirilmeli.
class BirlikteTextField extends StatefulWidget {
  const BirlikteTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.errorText,
    this.required = false,
    this.enabled = true,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;

  /// Doluysa alan hata görünümüne geçer ve yardımcı metnin yerini alır.
  final String? errorText;
  final bool required;
  final bool enabled;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<BirlikteTextField> createState() => _BirlikteTextFieldState();
}

class _BirlikteTextFieldState extends State<BirlikteTextField> {
  late final FocusNode _focus = FocusNode()..addListener(_onFocusChange);
  bool _focused = false;

  void _onFocusChange() => setState(() => _focused = _focus.hasFocus);

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  static const _fieldHeight = 48.0;
  static const _rowGap = 8.0;
  static const _inlineGap = 4.0;

  /// Çerçeve her durumda çizilir — odakta/hatada yalnızca rengi değişir.
  /// Yoksa çerçeve eklendiği an iç kutu daralıp metin 1.5 px zıplıyor.
  static const _borderWidth = 1.5;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    final borderColor = switch ((hasError, _focused)) {
      (true, _) => AppColors.borderError,
      (false, true) => AppColors.borderFocus,
      // Şeffaf: yer kaplar ama görünmez, böylece yerleşim sabit kalır.
      _ => const Color(0x00000000),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: AppTypography.labelLarge.copyWith(
                color: widget.enabled
                    ? AppColors.textPrimary
                    : AppColors.textDisabled,
              ),
            ),
            if (widget.required) ...[
              const SizedBox(width: _inlineGap),
              Text(
                '*',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textError,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: _rowGap),
        Container(
          height: _fieldHeight,
          // Figma iç boşluğu 12; çerçeve içeriden yer yediği için çıkarılıyor,
          // metnin yatay konumu her durumda aynı kalıyor.
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4 - _borderWidth,
          ),
          decoration: BoxDecoration(
            color: widget.enabled
                ? AppColors.surfaceSunken
                : AppColors.actionDisabled,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: borderColor, width: _borderWidth),
          ),
          // `expands` alanı dikeyde doldurur: 48 px'in her yerine dokunmak
          // odaklıyor, metin dikey ortada kalıyor.
          child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              enabled: widget.enabled,
              autofocus: widget.autofocus,
              expands: true,
              maxLines: null,
              minLines: null,
              textAlignVertical: TextAlignVertical.center,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              inputFormatters: widget.inputFormatters,
              maxLength: widget.maxLength,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              cursorColor: AppColors.brand,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: widget.hint,
                hintStyle: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textDisabled,
                ),
              ),
            ),
          ),
        if (hasError || widget.helper != null) ...[
          const SizedBox(height: _rowGap),
          Text(
            widget.errorText ?? widget.helper!,
            style: AppTypography.caption.copyWith(
              color: hasError ? AppColors.textError : AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
