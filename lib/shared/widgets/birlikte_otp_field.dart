import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';

/// Tek kullanımlık kod alanı (Figma: `otp` 190:52 — 6 kutu, 48x60, gap 8).
///
/// Görünürde kutular var, girişi tek bir görünmez [EditableText] alıyor:
/// yapıştırma, klavyeden silme ve otomatik SMS doldurma böyle tek yerden
/// çalışıyor. Aktif kutu Figma'daki gibi 2dp marka çerçevesi ve yanıp sönen
/// imleç gösterir.
class BirlikteOtpField extends StatefulWidget {
  const BirlikteOtpField({
    super.key,
    required this.onChanged,
    this.length = 6,
    this.onCompleted,
    this.autofocus = true,
    this.hasError = false,
  });

  final int length;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;
  final bool autofocus;

  /// Doluysa tüm kutular hata çerçevesine geçer.
  final bool hasError;

  @override
  State<BirlikteOtpField> createState() => _BirlikteOtpFieldState();
}

class _BirlikteOtpFieldState extends State<BirlikteOtpField>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  late final AnimationController _caret = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..repeat(reverse: true);

  static const _boxWidth = 48.0;
  static const _boxHeight = 60.0;
  static const _gap = AppSpacing.s3; // Figma: 8
  static const _caretWidth = 2.0;
  static const _caretHeight = 24.0;

  String get _value => _controller.text;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focus.addListener(_onFocusChanged);
  }

  void _onTextChanged() {
    setState(() {});
    widget.onChanged(_value);
    if (_value.length == widget.length) {
      _focus.unfocus();
      widget.onCompleted?.call(_value);
    }
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    _focus
      ..removeListener(_onFocusChanged)
      ..dispose();
    _caret.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Görünmez giriş alanı — kutuların arkasında, ölçüyü onlar belirliyor.
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: widget.autofocus,
              keyboardType: TextInputType.number,
              maxLength: widget.length,
              showCursor: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(height: 1),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _focus.requestFocus(),
          behavior: HitTestBehavior.opaque,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  _DigitBox(
                    digit: i < _value.length ? _value[i] : null,
                    active: _focus.hasFocus && i == _value.length,
                    hasError: widget.hasError,
                    caret: _caret,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DigitBox extends StatelessWidget {
  const _DigitBox({
    required this.digit,
    required this.active,
    required this.hasError,
    required this.caret,
  });

  final String? digit;
  final bool active;
  final bool hasError;
  final Animation<double> caret;

  @override
  Widget build(BuildContext context) {
    final border = switch ((hasError, active)) {
      (true, _) => Border.all(color: AppColors.borderError, width: 2),
      (false, true) => Border.all(color: AppColors.borderBrand, width: 2),
      _ => null,
    };

    return Container(
      width: _BirlikteOtpFieldState._boxWidth,
      height: _BirlikteOtpFieldState._boxHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: border,
      ),
      child: switch (digit) {
        final d? => Text(
          d,
          style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
        ),
        _ when active => FadeTransition(
          opacity: caret,
          child: Container(
            width: _BirlikteOtpFieldState._caretWidth,
            height: _BirlikteOtpFieldState._caretHeight,
            color: AppColors.brand,
          ),
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
