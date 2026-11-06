import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/communication_consent_page.dart';
import '../features/auth/presentation/institution_match_page.dart';
import '../features/auth/presentation/interest_selection_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/sms_verification_page.dart';
import '../features/auth/presentation/verification_error_page.dart';
import '../features/auth/presentation/welcome_page.dart';
import '../features/campaigns/presentation/campaign_detail_page.dart';
import '../features/campaigns/presentation/campaigns_list_page.dart';
import '../features/kandas/presentation/kandas_page.dart';
import '../features/wallet/presentation/wallet_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/profile/presentation/communication_preferences_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../shared/widgets/app_shell.dart';
import '../shared/widgets/birlikte_bottom_nav.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../core/app_config/app_config_repository.dart';
import '../features/splash/presentation/force_update_page.dart';
import '../features/splash/presentation/maintenance_page.dart';
import '../features/splash/presentation/splash_page.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_typography.dart';
import '../core/birlikte_api/birlikte_session_provider.dart';
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
  final refresh = ValueNotifier<int>(0);
  final sub = ref.listen<bool>(
    birlikteSessionProvider,
    (_, _) => refresh.value++,
  );
  ref.onDispose(() {
    sub.close();
    refresh.dispose();
  });

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    refreshListenable: refresh,

    // Oturumsuz kullanıcı korumalı ekranlara giremez; oturumlu kullanıcı
    // giriş ekranlarında takılı kalmaz.
    redirect: (context, state) {
      final loggedIn = ref.read(birlikteSessionProvider);
      final location = state.matchedLocation;

      const publicRoutes = {
        Routes.splash,
        Routes.maintenance,
        Routes.forceUpdate,
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
        path: Routes.maintenance,
        name: 'maintenance',
        builder: (context, state) =>
            MaintenancePage(message: state.extra as String?),
      ),
      GoRoute(
        path: Routes.forceUpdate,
        name: 'force-update',
        builder: (context, state) =>
            ForceUpdatePage(info: state.extra as GuncellemeBilgisi?),
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
        path: Routes.communicationConsent,
        name: 'communication-consent',
        builder: (context, state) => const CommunicationConsentPage(),
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
      GoRoute(
        path: Routes.communicationPreferences,
        name: 'communication-preferences',
        builder: (context, state) => const CommunicationPreferencesPage(),
      ),
      // Alt navigasyonun 5 sekmesi — her biri kendi Navigator'ına sahip bir
      // "branch". Sekmeler arası geçişte push/pop animasyonu oynamaz ve her
      // sekme kendi durumunu (scroll konumu, form girdisi) korur; bu,
      // native uygulamalardaki tab bar davranışının aynısıdır.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        // Branch sırası `BirlikteTab.values` ile BİREBİR aynı olmak zorunda:
        // AppShell aktif sekmeyi `BirlikteTab.values[currentIndex]` ile
        // buluyor ve `goBranch(tab.index)` ile geçiş yapıyor. Sırayı elle
        // yazmak, araya yeni bir sekme eklendiğinde sessizce yanlış sekmeyi
        // vurgulamaya yol açar — bu yüzden enum üzerinden üretiliyor.
        branches: [
          for (final tab in BirlikteTab.values)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: tab.route,
                  name: tab.name,
                  builder: (context, state) => switch (tab) {
                    BirlikteTab.home => const HomePage(),
                    BirlikteTab.campaigns => const CampaignsListPage(),
                    BirlikteTab.wallet => const WalletPage(),
                    BirlikteTab.kandas => const KandasPage(),
                    BirlikteTab.profile => const ProfilePage(),
                  },
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
