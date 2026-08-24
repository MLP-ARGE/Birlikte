import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/birlikte_button.dart';
import '../../../shared/widgets/birlikte_segmented_control.dart';
import '../../../shared/widgets/birlikte_text_field.dart';

/// Giriş yöntemi — Figma'daki segmented control iki seçenek sunuyor.
enum LoginMethod { phone, tckn }

/// Giriş ekranı (Figma: `login-screen` 3:99 boş, 199:654 dolu).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _controller = TextEditingController();
  LoginMethod _method = LoginMethod.phone;

  /// Figma `content`: pl/pr 24, pt 32.
  static const _contentTop = 32.0;

  /// Logo ile başlık arasındaki spacer.
  static const _afterLogo = 36.0;

  /// Başlık ile segmented control arası.
  static const _afterHeading = 28.0;

  /// Segmented control ile input arası.
  static const _afterSegments = 24.0;

  /// Figma `safe-area` 28.
  static const _bottomInset = 28.0;

  /// Telefon: 10 hane, 5 ile başlar. TCKN: 11 hane.
  bool get _valid {
    final digits = _controller.text.replaceAll(RegExp(r'\D'), '');
    return switch (_method) {
      LoginMethod.phone => digits.length == 12 && digits.startsWith('905'),
      LoginMethod.tckn => digits.length == 11,
    };
  }

  void _onMethodChanged(LoginMethod method) {
    if (method == _method) return;
    setState(() {
      _method = method;
      _controller.clear();
    });
  }

  void _submit() => context.push(
    Routes.smsVerification,
    // TCKN ile girişte numara bilinmiyor; SMS ekranı null'ı karşılıyor.
    extra: _method == LoginMethod.phone ? _controller.text : null,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = _method == LoginMethod.phone;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        // Klavye açıldığında Scaffold body'yi küçültür; içerik burada
        // kaydırılabilir olduğu için taşma değil kaydırma olur. Sabit
        // Spacer'lı tek Column kullanmak (önceki hâl) klavye açılınca
        // "BOTTOM OVERFLOWED" hatasına yol açıyordu.
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
                    // Figma: heading gap 12.
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'Burada çalıştığın için sana özel ayrıcalıklara erişmek '
                      'üzeresin.',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: _afterHeading),
                    BirlikteSegmentedControl<LoginMethod>(
                      value: _method,
                      onChanged: _onMethodChanged,
                      segments: const [
                        BirlikteSegment(
                          value: LoginMethod.phone,
                          label: 'Telefon',
                        ),
                        BirlikteSegment(value: LoginMethod.tckn, label: 'TCKN'),
                      ],
                    ),
                    const SizedBox(height: _afterSegments),
                    BirlikteTextField(
                      key: ValueKey(_method),
                      controller: _controller,
                      label: isPhone ? 'Telefon numarası' : 'TC Kimlik No',
                      required: true,
                      hint: isPhone ? '+90 5__ ___ __ __' : '___________',
                      helper: isPhone
                          ? 'Kurumda kayıtlı numaranı gir.'
                          : 'Kurumda kayıtlı TC kimlik numaranı gir.',
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        if (isPhone)
                          const _PhoneNumberFormatter()
                        else
                          LengthLimitingTextInputFormatter(11),
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
            // Sabit alt bölüm — kaydırma alanının dışında, klavye açıkken de
            // her zaman görünür (Figma: legal metin + buton, safe-area 28).
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
                  // Figma: legal ile buton arası 16.
                  const SizedBox(height: AppSpacing.s5),
                  BirlikteButton(
                    label: 'Devam',
                    onPressed: _valid ? _submit : null,
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

/// `+90 5XX XXX XX XX` biçimlendirici.
///
/// Kullanıcının yazdığı her şeyi rakama indirger, baştaki `0`/`90` gürültüsünü
/// atar ve Figma'daki `+90 5__ ___ __ __` maskesine oturtur.
class _PhoneNumberFormatter extends TextInputFormatter {
  const _PhoneNumberFormatter();

  static const _prefix = '+90 ';

  /// Ülke kodundan sonraki grup uzunlukları: 5XX XXX XX XX.
  static const _groups = [3, 3, 2, 2];

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('90')) digits = digits.substring(2);
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    if (digits.length > 10) digits = digits.substring(0, 10);
    if (digits.isEmpty) return const TextEditingValue();

    final buffer = StringBuffer(_prefix);
    var i = 0;
    for (final size in _groups) {
      if (i >= digits.length) break;
      if (i > 0) buffer.write(' ');
      buffer.write(digits.substring(i, (i + size).clamp(0, digits.length)));
      i += size;
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
