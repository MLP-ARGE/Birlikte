import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/institution_match_page.dart';
import '../features/auth/presentation/interest_selection_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/sms_verification_page.dart';
import '../features/auth/presentation/verification_error_page.dart';
import '../features/auth/presentation/welcome_page.dart';
import '../features/home/presentation/home_page.dart';
import '../shared/pages/coming_soon_page.dart';
import '../shared/widgets/birlikte_bottom_nav.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/splash/presentation/splash_page.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_typography.dart';
import 'routes.dart';

/// Uygulamanın rota tablosu.
///
/// Figma prototip akışı (başlangıç 3:12):
/// splash → onboarding → login → sms-verification → welcome →
/// institution-match → interest-selection → home.
///
/// Doğrulama başarısız olursa `verification-error` devreye girer.
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
        path: Routes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: Routes.smsVerification,
        name: 'sms-verification',
        // Login ekranı biçimlendirilmiş numarayı `extra` ile geçiriyor;
        // TCKN ile girişte null.
        builder: (context, state) =>
            SmsVerificationPage(phone: state.extra as String?),
      ),
      GoRoute(
        path: Routes.verificationError,
        name: 'verification-error',
        builder: (context, state) =>
            VerificationErrorPage(attemptedValue: state.extra as String?),
      ),
      GoRoute(
        path: Routes.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: Routes.institutionMatch,
        name: 'institution-match',
        builder: (context, state) => const InstitutionMatchPage(),
      ),
      GoRoute(
        path: Routes.interestSelection,
        name: 'interest-selection',
        builder: (context, state) => const InterestSelectionPage(),
      ),
      GoRoute(
        path: Routes.home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      // Alt navigasyonun diğer sekmeleri. Tasarımları Figma'da var; ekranları
      // kurulana kadar iskele sayfaya düşüyor, navigasyon çalışır kalsın.
      for (final tab in BirlikteTab.values)
        if (tab != BirlikteTab.home)
          GoRoute(
            path: tab.route,
            name: tab.name,
            builder: (context, state) => ComingSoonPage(tab: tab),
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
