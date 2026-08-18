import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/presentation/home_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/splash/presentation/splash_page.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_typography.dart';
import 'routes.dart';

/// Uygulamanın rota tablosu (Figma prototip akışı: 3:12 → onboarding → login → …).
///
/// Kimlik doğrulama ekranları (login, sms, welcome, institution-match,
/// interest-selection) sırayla eklenecek.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: Routes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: Routes.home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          child: Text(
            'Sayfa bulunamadı\n${state.uri}',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
        ),
      ),
    ),
  );
});
