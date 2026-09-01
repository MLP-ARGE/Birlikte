import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/institution_match_page.dart';
import '../features/auth/presentation/interest_selection_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/sms_verification_page.dart';
import '../features/auth/presentation/verification_error_page.dart';
import '../features/auth/presentation/welcome_page.dart';
import '../features/campaigns/presentation/campaign_detail_page.dart';
import '../features/campaigns/presentation/campaigns_list_page.dart';
import '../features/home/presentation/home_page.dart';
import '../shared/pages/coming_soon_page.dart';
import '../shared/widgets/app_shell.dart';
import '../shared/widgets/birlikte_bottom_nav.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/splash/presentation/splash_page.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_typography.dart';
import '../core/supabase/supabase_client_provider.dart';
import 'routes.dart';

/// Uygulamanın rota tablosu.
///
/// Figma prototip akışı (başlangıç 3:12):
/// splash → onboarding → login → sms-verification → welcome →
/// institution-match → interest-selection → home.
///
/// Doğrulama başarısız olursa `verification-error` devreye girer.
final routerProvider = Provider<GoRouter>((ref) {
  // Oturum değiştikçe yönlendirme yeniden değerlendirilsin.
  final auth = ref.watch(supabaseProvider).auth;
  final refresh = ValueNotifier<int>(0);
  final sub = auth.onAuthStateChange.listen((_) => refresh.value++);
  ref.onDispose(() {
    sub.cancel();
    refresh.dispose();
  });

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    refreshListenable: refresh,

    // Oturumsuz kullanıcı korumalı ekranlara giremez; oturumlu kullanıcı
    // giriş ekranlarında takılı kalmaz.
    redirect: (context, state) {
      // Taze okuma: bkz. sessionCheckProvider açıklaması.
      final loggedIn = ref.read(sessionCheckProvider)();
      final location = state.matchedLocation;

      const publicRoutes = {
        Routes.splash,
        Routes.onboarding,
        Routes.login,
        Routes.smsVerification,
        Routes.verificationError,
      };
      final isPublic = publicRoutes.contains(location);

      if (!loggedIn && !isPublic) return Routes.login;

      // Giriş yapmış kullanıcı login/sms ekranına dönerse ana sayfaya al.
      // Splash ve onboarding hariç: onlar kendi yönlendirmelerini yapıyor,
      // welcome/institution-match/interest-selection ise giriş sonrası
      // akışın parçası.
      if (loggedIn &&
          (location == Routes.login || location == Routes.smsVerification)) {
        return Routes.home;
      }

      return null;
    },
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
        // Login ekranı hem girilen değeri hem maskeli numarayı taşıyor.
        builder: (context, state) => SmsVerificationPage(
          args: state.extra as SmsVerificationArgs,
        ),
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
      // Kampanya detayı bilinçli olarak shell'in DIŞINDA, kök seviyede bir
      // rota — Figma'da bu ekranda alt navigasyon yok (CTA bar en altta).
      // Branch içine gömülseydi AppShell'in bottomNavigationBar'ı her zaman
      // görünür kalırdı; kök seviyede olması ekranı tam kaplıyor ve normal
      // push/pop geçiş animasyonu alıyor — bu da doğru, çünkü "derine giriş"
      // sekme değişimiyle aynı hareket değil.
      GoRoute(
        path: Routes.campaignDetailSegment,
        name: 'campaign-detail',
        builder: (context, state) => CampaignDetailPage(
          campaignId: state.pathParameters['id']!,
        ),
      ),
      // Alt navigasyonun 5 sekmesi — her biri kendi Navigator'ına sahip bir
      // "branch". Sekmeler arası geçişte push/pop animasyonu oynamaz ve her
      // sekme kendi durumunu (scroll konumu, form girdisi) korur; bu,
      // native uygulamalardaki tab bar davranışının aynısıdır.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                name: 'home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.campaigns,
                name: BirlikteTab.campaigns.name,
                builder: (context, state) => const CampaignsListPage(),
              ),
            ],
          ),
          // Tasarımları Figma'da var; ekranları kurulana kadar iskele
          // sayfaya düşüyor, navigasyon çalışır kalsın.
          for (final tab in BirlikteTab.values)
            if (tab != BirlikteTab.home && tab != BirlikteTab.campaigns)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: tab.route,
                    name: tab.name,
                    builder: (context, state) => ComingSoonPage(tab: tab),
                  ),
                ],
              ),
        ],
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
