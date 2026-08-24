import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/birlikte_app_bar.dart';
import '../../../shared/widgets/birlikte_button.dart';
import '../../../shared/widgets/birlikte_otp_field.dart';

/// SMS doğrulama (Figma: `sms-verification` 3:127 boş, 199:783 dolu).
class SmsVerificationPage extends StatefulWidget {
  const SmsVerificationPage({super.key, this.phone});

  /// Login ekranından gelen, biçimlendirilmiş numara (`+90 5XX XXX XX XX`).
  /// TCKN ile girişte bilinmediği için null olabilir.
  final String? phone;

  @override
  State<SmsVerificationPage> createState() => _SmsVerificationPageState();
}

class _SmsVerificationPageState extends State<SmsVerificationPage> {
  /// Figma'daki sayaç `00:45` ile başlıyor.
  static const _resendCooldown = Duration(seconds: 45);
  static const _codeLength = 6;

  /// Figma `content`: pt 8. Başlık ile OTP arası 32, OTP ile sayaç arası 24.
  static const _contentTop = 8.0;
  static const _afterHeading = 32.0;
  static const _afterOtp = 24.0;
  static const _bottomInset = 28.0;

  Timer? _timer;
  Duration _remaining = _resendCooldown;
  String _code = '';

  bool get _canResend => _remaining == Duration.zero;
  bool get _complete => _code.length == _codeLength;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _remaining = _resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= const Duration(seconds: 1)) {
        timer.cancel();
        setState(() => _remaining = Duration.zero);
      } else {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// TODO(api): doğrulama ucu eşleşme bulamazsa `Routes.verificationError`'a
  /// denenen numarayla gidilecek. Şu an backend olmadığı için hata yolu
  /// yalnızca rota üzerinden erişilebilir; ekran hazır.
  void _verify() => context.push(Routes.welcome);

  /// `+90 532 123 45 48` → `+90 532 *** ** 48`, Figma'daki maske:
  /// ülke kodu ve ilk grup açık, ortadaki iki grup yıldızlı, son grup açık.
  String get _description {
    final phone = widget.phone;
    if (phone == null) {
      return 'Kayıtlı numarana gönderdiğimiz $_codeLength haneli kodu gir.';
    }
    final parts = phone.split(' ');
    final masked = parts.length == 5
        ? [
            parts[0],
            parts[1],
            '*' * parts[2].length,
            '*' * parts[3].length,
            parts[4],
          ].join(' ')
        : phone;
    return '$masked numarasına gönderdiğimiz $_codeLength haneli kodu gir.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BirlikteAppBar(
              onBack: context.canPop() ? context.pop : null,
              onClose: () => context.go(Routes.login),
            ),
            Expanded(
              // Klavye açıldığında bu alan küçülür; içerik kaydırılabilir
              // olduğu için taşma değil kaydırma olur.
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  _contentTop,
                  AppSpacing.screenH,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Doğrulama kodu', style: AppTypography.display),
                    // Figma: heading gap 12.
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      _description,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: _afterHeading),
                    SizedBox(
                      height: 60,
                      child: BirlikteOtpField(
                        length: _codeLength,
                        onChanged: (code) => setState(() => _code = code),
                        onCompleted: (_) => _verify(),
                      ),
                    ),
                    const SizedBox(height: _afterOtp),
                    _ResendRow(
                      remaining: _remaining,
                      onResend: _canResend ? _startCountdown : null,
                    ),
                  ],
                ),
              ),
            ),
            // Sabit alt bölüm — kaydırma alanının dışında, klavye açıkken de
            // her zaman görünür (Figma: safe-area 28).
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.s5,
                AppSpacing.screenH,
                _bottomInset,
              ),
              child: BirlikteButton(
                label: 'Doğrula',
                onPressed: _complete ? _verify : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Kodu tekrar gönder" + geri sayım rozeti (Figma: `resend-row` 190:64).
class _ResendRow extends StatelessWidget {
  const _ResendRow({required this.remaining, required this.onResend});

  final Duration remaining;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final enabled = onResend != null;

    return Row(
      children: [
        GestureDetector(
          onTap: onResend,
          child: Text(
            'Kodu tekrar gönder',
            style: AppTypography.buttonSmall.copyWith(
              color: enabled ? AppColors.textBrand : AppColors.textDisabled,
            ),
          ),
        ),
        const Spacer(),
        if (!enabled)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceSunken,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Row(
              children: [
                const Icon(
                  AppIcons.clock,
                  size: 14,
                  color: AppColors.iconSubtle,
                ),
                // Figma: rozet içi gap 6.
                const SizedBox(width: 6),
                Text(
                  _format(remaining),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _format(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
