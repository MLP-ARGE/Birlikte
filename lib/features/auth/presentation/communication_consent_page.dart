import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/birlikte_api/birlikte_api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/birlikte_alert_dialog.dart';
import '../../../shared/widgets/birlikte_button.dart';
import '../../../shared/widgets/birlikte_switch.dart';
import '../data/communication_preferences_repository.dart';

/// Giriş (ve varsa KVKK onayı) bittikten sonra `GET /api/me/iletisim-
/// tercihleri`'ni kontrol eder; `sorulmali: true` ise bu ekranı gösterip
/// kullanıcının kararını bekler, değilse doğrudan Welcome'a geçer.
///
/// Uç hata verirse (ağ/sunucu) akışı KİLİTLEMİYORUZ — izin sorusu
/// önemli ama giriş akışını bloke edecek kadar kritik değil; `/api/app/
/// config` için uygulanan "hata = normal akışa devam" kuralıyla aynı
/// yaklaşım.
Future<void> continueAfterLoginConsents(
  BuildContext context,
  WidgetRef ref,
) async {
  try {
    final prefs = await ref
        .read(communicationPreferencesRepositoryProvider)
        .fetch();
    if (prefs.sorulmali && context.mounted) {
      context.go(Routes.communicationConsent);
      return;
    }
  } catch (_) {
    // yutuluyor — aşağıda Welcome'a devam ediliyor.
  }
  if (context.mounted) context.go(Routes.welcome);
}

/// İletişim izni ekranı (kampanya push/SMS/e-posta).
///
/// Kampanya bildirimi VARSAYILAN AÇIK (opt-out): kullanıcı hiç karar
/// vermese bile bildirim alır, yalnızca açıkça kapattığı kanal durur. Bu
/// yüzden anahtarlar burada "açık" başlıyor — ekran, kullanıcıya
/// istemediğini KAPATMA fırsatı veriyor, izin İSTEMİYOR.
///
/// GEÇİCİ METİN: hukuk birimi izin metnini henüz hazırlamadı (bkz.
/// `communication_preferences_repository.dart`'taki
/// `communicationConsentTextVersion` notu) — aşağıdaki açıklama yer
/// tutucudur, gerçek metin gelince değiştirilmeli.
class CommunicationConsentPage extends ConsumerStatefulWidget {
  const CommunicationConsentPage({super.key});

  @override
  ConsumerState<CommunicationConsentPage> createState() =>
      _CommunicationConsentPageState();
}

class _CommunicationConsentPageState
    extends ConsumerState<CommunicationConsentPage> {
  bool _push = true;
  bool _sms = true;
  bool _eposta = true;
  bool _submitting = false;

  Future<void> _continue() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await ref.read(communicationPreferencesRepositoryProvider).save({
        CommunicationChannel.push: _push,
        CommunicationChannel.sms: _sms,
        CommunicationChannel.eposta: _eposta,
      });
      if (!mounted) return;
      context.go(Routes.welcome);
    } on BirlikteApiException catch (e) {
      await showBirlikteAlert(context, title: 'Kaydedilemedi', message: e.message);
    } on BirlikteApiNetworkException catch (e) {
      await showBirlikteAlert(context, title: 'Kaydedilemedi', message: e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.s6,
            AppSpacing.screenH,
            AppSpacing.s6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kampanya Bildirimleri', style: AppTypography.display),
              const SizedBox(height: AppSpacing.s4),
              Text(
                'Sana özel kampanya ve fırsatlardan haberdar olman için bu '
                'kanallar açık. İstemediğini kapatabilirsin. Kupon ve '
                'oturum gibi hizmet bildirimleri bu seçimden etkilenmez, '
                'her durumda gelir.',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.s7),
              _ChannelTile(
                icon: AppIcons.bell,
                label: 'Push bildirimi',
                value: _push,
                onChanged: (v) => setState(() => _push = v),
              ),
              _ChannelTile(
                icon: AppIcons.messageSquare,
                label: 'SMS',
                value: _sms,
                onChanged: (v) => setState(() => _sms = v),
              ),
              _ChannelTile(
                icon: AppIcons.mail,
                label: 'E-posta',
                value: _eposta,
                onChanged: (v) => setState(() => _eposta = v),
              ),
              const Spacer(),
              BirlikteButton(
                label: 'Devam Et',
                isLoading: _submitting,
                onPressed: _submitting ? null : _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
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
          BirlikteSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
