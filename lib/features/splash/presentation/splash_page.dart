import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_dimens.dart';

/// Açılış ekranı.
///
/// !!! PLACEHOLDER !!! Figma'daki gerçek splash tasarımıyla değişecek.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Gerçek akışta: oturum kontrolü, uzaktan config, zorunlu güncelleme.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppConfig.appName,
              style: theme.textTheme.displayMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: AppSize.iconMd,
              height: AppSize.iconMd,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
