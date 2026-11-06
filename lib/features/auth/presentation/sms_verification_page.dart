import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/birlikte_alert_dialog.dart';
import '../../../shared/widgets/birlikte_app_bar.dart';
import '../../../shared/widgets/birlikte_button.dart';
import '../../../shared/widgets/birlikte_otp_field.dart';
import '../data/birlikte_auth_repository.dart';
import 'communication_consent_page.dart';

/// Login ekranından SMS ekranına taşınan bilgi.
class SmsVerificationArgs {
  const SmsVerificationArgs({
    required this.smsGuid,
    required this.gecerlilikSaniye,
    required this.kimlikNo,
    required this.dogumTarihi,
  });

  /// Sunucudaki SMS denemesinin kimliği.
  final String smsGuid;

  /// Kodun geçerlilik süresi (sn) — sayaç buradan başlıyor.
  final int gecerlilikSaniye;

  /// "Yeni kod al" için bellekte tutuluyor. TC kimlik no + doğum tarihi
  /// parola kadar hassas değil (ikisi de zaten kimlik belgesinde yazılı),
  /// bu yüzden PDKS'deki gibi "baştan gir" zorunluluğu yok — gerçek bir
  /// yeniden gönderim yapılabiliyor. Diske hiç yazılmıyor, yalnızca bu
  /// ekranın ömrü boyunca bellekte duruyor.
  final String kimlikNo;
  final String dogumTarihi;
}

/// SMS doğrulama (Figma: `sms-verification` 3:127 boş, 199:783 dolu).
class SmsVerificationPage extends ConsumerStatefulWidget {
  const SmsVerificationPage({super.key, required this.args});

  final SmsVerificationArgs args;

  @override
  ConsumerState<SmsVerificationPage> createState() =>
      _SmsVerificationPageState();
}

class _SmsVerificationPageState extends ConsumerState<SmsVerificationPage> {
  static const _codeLength = 6;

  static const _contentTop = 8.0;
  static const _afterHeading = 32.0;
  static const _afterOtp = 24.0;
  static const _bottomInset = 28.0;

  /// Sunucudan gelen `smsGuid` sabit değil: "yeni kod al" yeni bir guid
  /// üretir, bu yüzden state'te tutulup güncelleniyor.
  late String _smsGuid = widget.args.smsGuid;

  Timer? _timer;
  late Duration _remaining = Duration(seconds: widget.args.gecerlilikSaniye);
  String _code = '';
  bool _verifying = false;
  bool _resending = false;

  bool get _canResend =>
      _remaining == Duration.zero && !_resending && !_verifying;
  bool get _complete => _code.length == _codeLength;

  @override
  void initState() {
    super.initState();
    _startCountdown(Duration(seconds: widget.args.gecerlilikSaniye));
  }

  /// Yeni kod ister. TC no + doğum tarihi bellekte tutulduğu için gerçek bir
  /// yeniden gönderim — PDKS'deki "giriş ekranına dön" geçici çözümünün
  /// aksine.
  Future<void> _resend() async {
    if (_resending) return;
    setState(() => _resending = true);
    try {
      final challenge = await ref
          .read(birlikteAuthRepositoryProvider)
          .requestOtp(
            kimlikNo: widget.args.kimlikNo,
            dogumTarihi: widget.args.dogumTarihi,
          );
      if (!mounted) return;
      setState(() => _smsGuid = challenge.smsGuid);
      _startCountdown(Duration(seconds: challenge.gecerlilikSaniye));
    } on AuthException {
      if (!mounted) return;
      await showBirlikteAlert(
        context,
        title: 'Kod gönderilemedi',
        message: 'Lütfen tekrar dene.',
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _startCountdown(Duration from) {
    _timer?.cancel();
    setState(() => _remaining = from);
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

  /// Kodu doğrular; başarılıysa Supabase oturumu kurulur ve profil
  /// doldurulur.
  Future<void> _verify() async {
    if (_verifying) return;
    setState(() => _verifying = true);

    try {
      final result = await ref
          .read(birlikteAuthRepositoryProvider)
          .verifyOtp(smsGuid: _smsGuid, code: _code);
      if (!mounted) return;

      if (result.kapatilanCihazlar.isNotEmpty) {
        await showBirlikteAlert(
          context,
          title: 'Diğer oturum kapatıldı',
          message:
              '${result.kapatilanCihazlar.join(", ")} cihazındaki oturum '
              'kapatıldı.',
        );
        if (!mounted) return;
      }

      unawaited(continueAfterLoginConsents(context, ref));
    } on AuthException catch (e) {
      if (!mounted) return;
      final message = switch (e.failure) {
        AuthFailure.invalidCode =>
          e.message?.isNotEmpty == true
              ? e.message!
              : 'Kod hatalı veya süresi dolmuş.',
        AuthFailure.sessionExpired =>
          'Oturum başka bir cihazdan kapatıldı. Lütfen tekrar giriş yap.',
        _ => 'Bağlantı kurulamadı. Lütfen tekrar dene.',
      };
      await showBirlikteAlert(context, title: 'Doğrulanamadı', message: message);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  String get _description =>
      'Kayıtlı numarana gönderdiğimiz $_codeLength haneli kodu gir.';

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
                      busy: _resending,
                      onResend: _canResend ? _resend : null,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.s5,
                AppSpacing.screenH,
                _bottomInset,
              ),
              child: BirlikteButton(
                label: 'Doğrula',
                isLoading: _verifying,
                onPressed: _complete && !_verifying ? _verify : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Yeni kod al" + geri sayım rozeti (Figma: `resend-row` 190:64).
class _ResendRow extends StatelessWidget {
  const _ResendRow({
    required this.remaining,
    required this.busy,
    required this.onResend,
  });

  final Duration remaining;
  final bool busy;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final enabled = onResend != null;

    return Row(
      children: [
        GestureDetector(
          onTap: onResend,
          child: Text(
            busy ? 'Gönderiliyor…' : 'Yeni kod al',
            style: AppTypography.buttonSmall.copyWith(
              color: enabled ? AppColors.textBrand : AppColors.textDisabled,
            ),
          ),
        ),
        const Spacer(),
        if (!enabled && !busy)
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
