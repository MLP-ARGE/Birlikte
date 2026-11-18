import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/birlikte_alert_dialog.dart';
import '../../../../shared/widgets/birlikte_button.dart';
import '../../../../shared/widgets/birlikte_checkbox.dart';
import '../../../../shared/widgets/birlikte_chip.dart';
import '../../../home/application/home_providers.dart';
import '../../../home/data/home_repository.dart';

/// `PUT /api/me/kan-grubu`'nun kabul ettiği değerler.
const kBloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', '0+', '0-'];

/// Kan grubu ekleme/değiştirme sheet'i (Profil → "Kan grubu").
///
/// Kan grubu özel nitelikli kişisel veri — backend açık rıza olmadan
/// kaydı reddediyor (`ACIK_RIZA_GEREKLI`), bu yüzden onay kutusu
/// kaydetmeden önce işaretlenmiş olmalı.
Future<void> showBloodTypeSheet(BuildContext context, String? current) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => _BloodTypeSheet(current: current),
  );
}

class _BloodTypeSheet extends ConsumerStatefulWidget {
  const _BloodTypeSheet({required this.current});

  final String? current;

  @override
  ConsumerState<_BloodTypeSheet> createState() => _BloodTypeSheetState();
}

class _BloodTypeSheetState extends ConsumerState<_BloodTypeSheet> {
  late String? _selected = widget.current;
  bool _acikRiza = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.s3,
          AppSpacing.screenH,
          AppSpacing.s5 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s5),
            Text('Kan grubu', style: AppTypography.h3),
            const SizedBox(height: 6),
            Text(
              'Kan bağışı taleplerinde sana uygun olanları görebilmen için '
              'kullanılır.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            Wrap(
              spacing: AppSpacing.s3,
              runSpacing: AppSpacing.s3,
              children: [
                for (final type in kBloodTypes)
                  BirlikteChip(
                    label: type,
                    selected: _selected == type,
                    onTap: () => setState(
                      () => _selected = _selected == type ? null : type,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s6),
            BirlikteCheckbox(
              value: _acikRiza,
              onChanged: (v) => setState(() => _acikRiza = v),
              label: 'Kan grubumun kan bağışı taleplerinde eşleştirme için '
                  'kullanılmasına açık rızam vardır.',
            ),
            const SizedBox(height: AppSpacing.s6),
            BirlikteButton(
              label: 'Kaydet',
              isLoading: _saving,
              onPressed: _canSave ? _save : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Boşaltmak (kan grubunu silmek) için açık rıza gerekmiyor — yalnızca
  /// bir değer SEÇERKEN zorunlu.
  bool get _canSave =>
      !_saving && (_selected == null || _acikRiza) && _selected != widget.current;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(homeRepositoryProvider).saveBloodType(_selected);
      ref.invalidate(bloodTypeAsyncProvider);
      ref.invalidate(bloodRequestsAsyncProvider);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      await showBirlikteApiErrorAlert(
        context,
        e,
        title: 'Kaydedilemedi',
        codeOverrides: const {
          'ACIK_RIZA_GEREKLI': 'Kaydetmek için açık rıza onayını '
              'işaretlemen gerekiyor.',
        },
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
