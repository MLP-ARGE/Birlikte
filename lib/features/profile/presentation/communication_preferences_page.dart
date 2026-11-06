import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/birlikte_alert_dialog.dart';
import '../../../shared/widgets/birlikte_app_bar.dart';
import '../../../shared/widgets/birlikte_switch.dart';
import '../../auth/data/communication_preferences_repository.dart';

/// Ayarlar ekranındaki "Bildirim tercihleri" — giriş sonrası gösterilen
/// `CommunicationConsentPage` ile aynı anahtarları kullanır, kullanıcı
/// istediği an izni geri çekebilir/verebilir (bkz. backend akışı: "Ayarlar
/// ekranında aynı anahtarları GET'ten doldurun ... değişince PUT atın").
class CommunicationPreferencesPage extends ConsumerWidget {
  const CommunicationPreferencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(communicationPreferencesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            BirlikteAppBar(onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: switch (async) {
                AsyncData(:final value) => _PreferencesBody(prefs: value),
                AsyncError() => _ErrorRetry(
                  onRetry: () => ref.invalidate(communicationPreferencesProvider),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferencesBody extends ConsumerStatefulWidget {
  const _PreferencesBody({required this.prefs});

  final CommunicationPreferences prefs;

  @override
  ConsumerState<_PreferencesBody> createState() => _PreferencesBodyState();
}

class _PreferencesBodyState extends ConsumerState<_PreferencesBody> {
  /// Kaydedilirken o kanalın switch'i devre dışı kalır — çift tıklamayla
  /// iki farklı değerin yarışmasını engeller.
  CommunicationChannel? _saving;

  Future<void> _toggle(CommunicationChannel kanal, bool value) async {
    setState(() => _saving = kanal);
    try {
      await ref
          .read(communicationPreferencesRepositoryProvider)
          .save({kanal: value});
      ref.invalidate(communicationPreferencesProvider);
    } catch (_) {
      if (mounted) {
        await showBirlikteAlert(
          context,
          title: 'Kaydedilemedi',
          message: 'Lütfen tekrar dene.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = widget.prefs;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.s3,
        AppSpacing.screenH,
        AppSpacing.s6,
      ),
      children: [
        Text('Kampanya Bildirimleri', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.s3),
        Text(
          'Kampanya ve fırsat bildirimlerini almak istediğin kanalları '
          'istediğin an değiştirebilirsin. Kupon ve oturum gibi hizmet '
          'bildirimleri bu seçimden etkilenmez.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s6),
        _ChannelRow(
          icon: AppIcons.bell,
          label: 'Push bildirimi',
          value: prefs.isEnabled(CommunicationChannel.push),
          loading: _saving == CommunicationChannel.push,
          onChanged: (v) => _toggle(CommunicationChannel.push, v),
        ),
        _ChannelRow(
          icon: AppIcons.messageSquare,
          label: 'SMS',
          value: prefs.isEnabled(CommunicationChannel.sms),
          loading: _saving == CommunicationChannel.sms,
          onChanged: (v) => _toggle(CommunicationChannel.sms, v),
        ),
        _ChannelRow(
          icon: AppIcons.mail,
          label: 'E-posta',
          value: prefs.isEnabled(CommunicationChannel.eposta),
          loading: _saving == CommunicationChannel.eposta,
          onChanged: (v) => _toggle(CommunicationChannel.eposta, v),
        ),
      ],
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.loading,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final bool loading;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
      child: Row(
        children: [
          Icon(icon, size: AppSize.iconInButton, color: AppColors.iconSubtle),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Text(label, style: AppTypography.labelLarge),
          ),
          if (loading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            BirlikteSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tercihler yüklenemedi.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          TextButton(onPressed: onRetry, child: const Text('Tekrar dene')),
        ],
      ),
    );
  }
}
