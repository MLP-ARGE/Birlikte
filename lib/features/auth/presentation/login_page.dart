import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/birlikte_button.dart';
import '../../../shared/widgets/birlikte_text_field.dart';
import '../data/auth_repository.dart';
import 'sms_verification_page.dart';

/// Giriş ekranı — MLPCARE PDKS kullanıcı adı ve parolasıyla.
///
/// Önceki sürümde telefon/TCKN seçimi vardı; kimlik doğrulama PDKS'ye
/// taşınınca kurumun kendi kullanıcı adı/parola çiftine geçildi.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _sending = false;
  String? _error;

  /// Figma `content`: pl/pr 24, pt 32.
  static const _contentTop = 32.0;
  static const _afterLogo = 36.0;
  static const _afterHeading = 28.0;
  static const _bottomInset = 28.0;

  bool get _valid =>
      _username.text.trim().isNotEmpty && _password.text.isNotEmpty;

  Future<void> _submit() async {
    if (_sending || !_valid) return;
    // Klavyeyi kapat: yanıt beklenirken ekranın tamamı görünsün.
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final challenge = await ref.read(authRepositoryProvider).requestOtp(
        username: _username.text.trim(),
        password: _password.text,
      );

      if (!mounted) return;
      unawaited(
        context.push(
          Routes.smsVerification,
          extra: SmsVerificationArgs(
            challengeId: challenge.challengeId,
            maskedPhone: challenge.maskedPhone,
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = switch (e.failure) {
        AuthFailure.invalidCredentials =>
          'Kullanıcı adı veya parola hatalı.',
        AuthFailure.branchNotMapped =>
          'Hesabın henüz tanımlanmamış. Lütfen İK ile iletişime geç.',
        _ => 'Bağlantı kurulamadı. Lütfen tekrar dene.',
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    Image.asset(AppAssets.logoBirlikte, height: 44),
                    const SizedBox(height: _afterLogo),
                    Text('Giriş yap', style: AppTypography.display),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'Burada çalıştığın için sana özel ayrıcalıklara erişmek '
                      'üzeresin.',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: _afterHeading),
                    BirlikteTextField(
                      controller: _username,
                      label: 'Kullanıcı adı',
                      required: true,
                      hint: 'ad.soyad',
                      helper: 'Kurum hesabınla aynı kullanıcı adı.',
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        // Kullanıcı adında boşluk yok; otomatik büyük harf
                        // düzeltmesinin bıraktığı boşlukları da eliyoruz.
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      ],
                      onChanged: (_) => setState(() => _error = null),
                    ),
                    const SizedBox(height: AppSpacing.s5),
                    BirlikteTextField(
                      controller: _password,
                      label: 'Parola',
                      required: true,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => setState(() => _error = null),
                      onSubmitted: (_) => _submit(),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Devam ederek Kullanım Koşulları ve KVKK Aydınlatma '
                    "Metni'ni okuduğunu kabul etmiş olursun.",
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (_error case final error?) ...[
                    const SizedBox(height: AppSpacing.s3),
                    Text(
                      error,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textError,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s5),
                  BirlikteButton(
                    label: 'Devam',
                    isLoading: _sending,
                    onPressed: _valid && !_sending ? _submit : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
