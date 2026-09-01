import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/routes.dart';
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
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // Oturum varsa doğrudan ana sayfaya; yoksa onboarding'e.
    final hasSession = Supabase.instance.client.auth.currentSession != null;
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
