import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_config/app_config_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/birlikte_alert_dialog.dart';
import '../../../shared/widgets/birlikte_button.dart';

/// Zorunlu güncelleme (`GET /api/app/config` → `guncelleme.durum: ZORUNLU`).
///
/// Kurulu sürüm `minSurum`'dan eski — uygulama kullandırılmıyor, tek çıkış
/// mağaza linki. Bilinçli olarak geri/atla yok (spec: "sadece 'Güncelle'
/// butonu göster").
class ForceUpdatePage extends StatelessWidget {
  const ForceUpdatePage({super.key, this.info});

  final GuncellemeBilgisi? info;

  Future<void> _openStore(BuildContext context) async {
    final url = info?.magazaUrl;
    if (url == null || url.isEmpty) {
      await showBirlikteAlert(
        context,
        title: 'Mağaza bağlantısı henüz tanımlanmadı.',
      );
      return;
    }
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);
    if (!ok && context.mounted) {
      await showBirlikteAlert(context, title: 'Bağlantı açılamadı');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.statusInfoSubtle,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.download,
                  size: 32,
                  color: AppColors.textInfo,
                ),
              ),
              const SizedBox(height: AppSpacing.s7),
              Text(
                'Güncelleme gerekli',
                style: AppTypography.display,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                info?.mesaj?.isNotEmpty == true
                    ? info!.mesaj!
                    : 'Devam edebilmen için uygulamayı güncellemen '
                          'gerekiyor.',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s7),
              BirlikteButton(
                label: 'Güncelle',
                onPressed: () => _openStore(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
