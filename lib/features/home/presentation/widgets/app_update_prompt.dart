import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/app_config/app_config_repository.dart';

class _AppNoticeShown extends Notifier<bool> {
  @override
  bool build() => false;

  void markShown() => state = true;
}

final _appNoticeShownProvider = NotifierProvider<_AppNoticeShown, bool>(
  _AppNoticeShown.new,
);

/// Splash'ta tespit edilen ÖNERİLEN güncelleme ve/veya duyuruyu, Home ilk
/// açıldığında bir kez gösterir. Bakım/ZORUNLU güncelleme splash'ın kendi
/// ekranlarında ele alınıyor — bu yalnızca engellemeyen bilgilendirmeler
/// için.
///
/// `missing_info_sheet.dart`/`push_notification_service.dart` ile aynı
/// desen: bayrağı `build()` SIRASINDA değil `addPostFrameCallback` içinde
/// işaretliyoruz.
void maybeShowAppNotice(BuildContext context, WidgetRef ref) {
  if (ref.read(_appNoticeShownProvider)) return;
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (ref.read(_appNoticeShownProvider)) return;
    ref.read(_appNoticeShownProvider.notifier).markShown();

    final config = ref.read(pendingAppNoticeProvider.notifier).consume();
    if (config == null || !context.mounted) return;

    if (config.guncelleme.durum == GuncellemeDurumu.onerilen) {
      await _showUpdateDialog(context, config.guncelleme);
      if (!context.mounted) return;
    }
    if (config.duyuru case final duyuru?) {
      await _showAnnouncementDialog(context, duyuru);
    }
  });
}

Future<void> _showUpdateDialog(
  BuildContext context,
  GuncellemeBilgisi guncelleme,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Yeni sürüm var'),
      content: Text(
        guncelleme.mesaj?.isNotEmpty == true
            ? guncelleme.mesaj!
            : 'Daha iyi bir deneyim için uygulamayı güncellemeni öneririz.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Sonra'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(dialogContext).pop();
            final url = guncelleme.magazaUrl;
            if (url == null || url.isEmpty) return;
            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            ).catchError((_) => false);
          },
          child: const Text('Güncelle'),
        ),
      ],
    ),
  );
}

Future<void> _showAnnouncementDialog(BuildContext context, AppDuyurusu duyuru) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(duyuru.baslik),
      content: Text(duyuru.metin),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Tamam'),
        ),
      ],
    ),
  );
}
