import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/routes.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/validation/tckn_validator.dart';
import '../../../shared/widgets/birlikte_alert_dialog.dart';
import '../../../shared/widgets/birlikte_button.dart';
import '../../../shared/widgets/birlikte_text_field.dart';
import '../data/birlikte_auth_repository.dart';
import 'sms_verification_page.dart';

/// Giriş ekranı — MLPCARE Birlikte mobil API'si üzerinden.
///
/// Önceki sürümde PDKS kullanıcı adı/parolası vardı; birlikte-api'ye
/// geçişle kimlik TC kimlik no + doğum tarihi çiftine döndü.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _tcController = TextEditingController();
  final _dobController = TextEditingController();
  bool _sending = false;

  static const _contentTop = 32.0;
  static const _afterLogo = 36.0;
  static const _afterHeading = 28.0;
  static const _bottomInset = 28.0;

  bool get _tcValid => TcknValidator.isValid(_tcController.text);

  /// gg.aa.yyyy → geçerli bir tarih mi. Gün/ay sınırları gerçek takvime göre
  /// (örn. 31.02 reddedilir) — `DateTime` kendisi bunu zaten kontrol ediyor.
  DateTime? get _birthDate {
    final digits = _dobController.text.replaceAll('.', '');
    if (digits.length != 8) return null;
    final day = int.tryParse(digits.substring(0, 2));
    final month = int.tryParse(digits.substring(2, 4));
    final year = int.tryParse(digits.substring(4, 8));
    if (day == null || month == null || year == null) return null;
    final date = DateTime(year, month, day);
    if (date.day != day || date.month != month || date.year != year) {
      return null;
    }
    final now = DateTime.now();
    if (year < now.year - 100 || date.isAfter(now)) return null;
    return date;
  }

  bool get _valid => _tcValid && _birthDate != null;

  Future<void> _submit() async {
    if (_sending || !_valid) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);

    final kimlikNo = _tcController.text;
    final birthDate = _birthDate!;
    // API yyyy-MM-dd bekliyor (saat dilimsiz tarih alanları için belgeli
    // kural).
    final dogumTarihi = DateFormat('yyyy-MM-dd').format(birthDate);

    try {
      final challenge = await ref
          .read(birlikteAuthRepositoryProvider)
          .requestOtp(kimlikNo: kimlikNo, dogumTarihi: dogumTarihi);

      if (!mounted) return;
      unawaited(
        context.push(
          Routes.smsVerification,
          extra: SmsVerificationArgs(
            smsGuid: challenge.smsGuid,
            gecerlilikSaniye: challenge.gecerlilikSaniye,
            // TC no + doğum tarihi parola kadar hassas değil; "yeni kod al"
            // bu ikisini yeniden göndermek için bellekte tutuluyor. Diske
            // hiç yazılmıyor.
            kimlikNo: kimlikNo,
            dogumTarihi: dogumTarihi,
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.failure == AuthFailure.missingInfo) {
        // SMS hiç gönderilmedi; tekrar denemenin anlamı yok — bilgi kurum
        // tarafında düzelmeli.
        await showBirlikteAlert(
          context,
          title: 'Giriş yapılamıyor',
          message: e.message?.isNotEmpty == true
              ? e.message!
              : 'Kaydınızda eksik bilgi var. Giriş yapabilmek için lütfen '
                    'kurumunuzla (İnsan Kaynakları / öğrenci işleri) '
                    'iletişime geçin.',
        );
        return;
      }
      await showBirlikteAlert(
        context,
        title: 'Giriş yapılamadı',
        message: switch (e.failure) {
          AuthFailure.invalidCredentials =>
            e.message?.isNotEmpty == true
                ? e.message!
                : 'TC kimlik no veya doğum tarihi hatalı.',
          _ => 'Bağlantı kurulamadı. Lütfen tekrar dene.',
        },
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _tcController.dispose();
    _dobController.dispose();
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
                      controller: _tcController,
                      label: 'TC Kimlik No',
                      required: true,
                      hint: '___________',
                      helper: _tcController.text.isEmpty || _tcValid
                          ? 'Kurumda kayıtlı TC kimlik numaranı gir.'
                          : null,
                      errorText: _tcController.text.isNotEmpty && !_tcValid
                          ? 'Geçersiz TC kimlik no.'
                          : null,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.s5),
                    BirlikteTextField(
                      controller: _dobController,
                      label: 'Doğum Tarihi',
                      required: true,
                      hint: 'gg.aa.yyyy',
                      helper: 'Örn. 15.03.1990',
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _BirthDateFormatter(),
                      ],
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) {
                        if (_valid) _submit();
                      },
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

/// `gg.aa.yyyy` biçimlendirici — kullanıcı yalnızca rakam yazar, noktalar
/// otomatik eklenir.
class _BirthDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 8) digits = digits.substring(0, 8);
    if (digits.isEmpty) return const TextEditingValue();

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) buffer.write('.');
      buffer.write(digits[i]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
