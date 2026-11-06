import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/birlikte_alert_dialog.dart';
import '../../../../shared/widgets/birlikte_button.dart';
import '../../../../shared/widgets/birlikte_info_card.dart';
import '../../../auth/data/profile_repository.dart';
import '../../../auth/domain/verified_profile.dart';

/// Oturum başına bir kez: eksik bilgi sheet'i zaten gösterildi mi.
///
/// Hem `WelcomePage` (ilk girişte, profil ilk kez gösterildiği an) hem
/// `HomePage`'den (Welcome'ı atlayan dönen kullanıcılarda) çağrılıyor;
/// ikisi de aynı bayrağı paylaştığı için aynı oturumda iki kez gösterilmez.
class MissingInfoPrompted extends Notifier<bool> {
  @override
  bool build() => false;

  void markShown() => state = true;
}

final missingInfoPromptedProvider =
    NotifierProvider<MissingInfoPrompted, bool>(MissingInfoPrompted.new);

/// Çıkışta çağrılır — bayrak sıfırlanmazsa bir sonraki (farklı hesap olası)
/// girişte eksik bilgisi olsa bile sheet hiç gösterilmez.
void resetMissingInfoPrompt(Ref ref) {
  ref.invalidate(missingInfoPromptedProvider);
}

/// Profilde cinsiyet/ad/soyad eksikse oturum başına bir kez sheet'i
/// zamanlar. Çağıran taraf her `build()`'de çağırabilir — koşul veya bayrak
/// uymuyorsa hiçbir şey yapmaz.
///
/// Bayrağı (`markShown`) build SIRASINDA değil, `addPostFrameCallback`
/// içinde güncelliyoruz: Riverpod, bir provider'ı widget ağacı inşa
/// edilirken değiştirmeye izin vermiyor ("Tried to modify a provider while
/// the widget tree was building") — bu kontrol gerçek eksik-bilgili bir
/// kullanıcıyla ilk denendiğinde tam da bu hatayı verdi.
void maybeShowMissingInfoSheet(
  BuildContext context,
  WidgetRef ref,
  VerifiedProfile? profile,
) {
  if (profile == null) return;
  if (!profile.genderMissing && !profile.nameMissingAtInstitution) return;
  if (ref.read(missingInfoPromptedProvider)) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Frame bitti; aynı anda başka bir çağrı bu arada bayrağı zaten
    // değiştirmiş olabilir (iki ekran aynı anda tetiklerse) — tekrar
    // kontrol ediyoruz.
    if (ref.read(missingInfoPromptedProvider)) return;
    ref.read(missingInfoPromptedProvider.notifier).markShown();
    if (context.mounted) showMissingInfoSheet(context, profile);
  });
}

/// Giriş sonrası eksik bilgi bildirimi (Figma'da ayrı bir ekran yok —
/// `GET /api/me`'nin `eksikBilgiler` listesine göre kuruldu).
///
/// Giriş engellenmiyor (yalnızca doğum tarihi/telefon eksikse engellenir,
/// bkz. `BILGI_EKSIK` giriş hatası); bu yüzden bu tam ekran bir kapı değil,
/// bir kerelik bir popup. Cinsiyet eksikse kullanıcı burada tamamlayabilir;
/// ad/soyad eksikse yalnızca bilgilendiriliyor, çünkü bu ikisi kurum
/// kaydından düzeltilir.
///
/// Uygulama genelindeki tek diyalog standardına uymak için `showDialog` ile
/// gösteriliyor — önceki sürümde `showModalBottomSheet` kullanılıyordu.
Future<void> showMissingInfoSheet(BuildContext context, VerifiedProfile profile) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: _MissingInfoDialog(profile: profile),
    ),
  );
}

class _MissingInfoDialog extends ConsumerStatefulWidget {
  const _MissingInfoDialog({required this.profile});

  final VerifiedProfile profile;

  @override
  ConsumerState<_MissingInfoDialog> createState() => _MissingInfoDialogState();
}

class _MissingInfoDialogState extends ConsumerState<_MissingInfoDialog> {
  bool _saving = false;
  String? _selectedGender;

  Future<void> _saveGender(String cinsiyet) async {
    setState(() {
      _saving = true;
      _selectedGender = cinsiyet;
    });
    try {
      await ref.read(profileRepositoryProvider).completeGender(cinsiyet);
      ref.invalidate(profileProvider);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _selectedGender = null;
      });
      await showBirlikteAlert(
        context,
        title: 'Kaydedilemedi',
        message: 'Lütfen tekrar dene.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bilgilerini tamamla', style: AppTypography.h4),
          const SizedBox(height: AppSpacing.s5),
          if (profile.genderMissing) ...[
            Text('Cinsiyetin', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.s3),
            Row(
              children: [
                Expanded(
                  child: BirlikteButton(
                    label: 'Kadın',
                    style: BirlikteButtonStyle.secondary,
                    isLoading: _saving && _selectedGender == 'K',
                    onPressed: _saving ? null : () => _saveGender('K'),
                  ),
                ),
                const SizedBox(width: AppSpacing.s4),
                Expanded(
                  child: BirlikteButton(
                    label: 'Erkek',
                    style: BirlikteButtonStyle.secondary,
                    isLoading: _saving && _selectedGender == 'E',
                    onPressed: _saving ? null : () => _saveGender('E'),
                  ),
                ),
              ],
            ),
            if (profile.nameMissingAtInstitution)
              const SizedBox(height: AppSpacing.s5),
          ],
          if (profile.nameMissingAtInstitution) ...[
            const BirlikteInfoCard(
              message: 'Kaydında ad/soyad bilgisi eksik. Bu bilgiyi '
                  'güncellemek için kurumunla (İnsan Kaynakları / öğrenci '
                  'işleri) iletişime geçmen gerekiyor.',
            ),
            const SizedBox(height: AppSpacing.s4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Anladım'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
