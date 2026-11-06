import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/app_config/app_config_repository.dart';
import '../../../core/birlikte_api/birlikte_session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

/// Açılış ekranı (Figma: splash-screen, 3:12).
///
/// Beyaz zemin, ortada MLPCARE üst yazısı + "Birlikte" logotype,
/// altında "Daha avantajlıyız".
///
/// TODO(assets): "Birlikte" el yazısı logosu Figma'dan SVG olarak alınıp
/// assets/images/ altına konacak; şu an tipografiyle yaklaştırılıyor.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Marka ekranının asgari süresiyle aynı anda başlıyor — ağ isteği yüzünden
    // açılış ekrisnın toplam süresi uzamıyor (ikisinden uzun olanı bekleniyor).
    final configFuture = ref.read(appConfigRepositoryProvider).fetch();
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    final config = await configFuture;
    if (!mounted) return;

    // Bakım modundaysa giriş ekranına hiç gidilmiyor (spec: `GET
    // /api/app/config`). Uç hata verirse `config` null döner — spec'in kendi
    // kuralı gereği akış KİLİTLENMİYOR, normal akışa devam ediliyor.
    if (config?.bakimModu ?? false) {
      context.go(Routes.maintenance, extra: config!.bakimMesaji);
      return;
    }
    if (config?.guncelleme.durum == GuncellemeDurumu.zorunlu) {
      context.go(Routes.forceUpdate, extra: config!.guncelleme);
      return;
    }
    // ÖNERİLEN güncelleme ve/veya duyuru engellemiyor — Home ilk açıldığında
    // bir kez gösterilmek üzere burada saklanıyor (bkz. `app_update_prompt.dart`).
    if (config != null &&
        (config.guncelleme.durum == GuncellemeDurumu.onerilen ||
            config.duyuru != null)) {
      ref.read(pendingAppNoticeProvider.notifier).set(config);
    }

    // Oturum varsa doğrudan ana sayfaya; yoksa onboarding'e. Tek kaynak
    // birlikte-api'nin SecureStorage'daki refresh token'ı (bkz.
    // BirlikteSessionNotifier) — Supabase oturum için kullanılmıyor.
    final hasSession = ref.read(birlikteSessionProvider);
    context.go(hasSession ? Routes.home : Routes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'MLPCARE',
              style: AppTypography.overline.copyWith(
                color: AppColors.brand,
                letterSpacing: 2.4,
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Birlikte',
              style: AppTypography.display.copyWith(
                color: AppColors.brand,
                fontSize: 56,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            Text(
              'Daha avantajlıyız',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
