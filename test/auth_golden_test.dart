// Auth akışındaki ekranların Figma tasarımıyla karşılaştırılması.
import 'package:birlikte/app/router.dart';
import 'package:birlikte/app/routes.dart';
import 'package:birlikte/core/theme/app_theme.dart';
import 'package:birlikte/features/auth/presentation/sms_verification_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';
import 'helpers/test_fonts.dart';
import 'helpers/test_supabase.dart';

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await initSupabaseForTests();
  });

  /// Verilen rotayı 390x844 (Figma kare ölçüsü) yüzeyde render eder.
  Future<void> pumpRoute(
    WidgetTester tester,
    String location, {
    Object? extra,
    bool loggedIn = true,
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: testOverrides(loggedIn: loggedIn),
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider)..go(location, extra: extra);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light,
          debugShowCheckedModeBanner: false,
          locale: const Locale('tr', 'TR'),
          supportedLocales: const [Locale('tr', 'TR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );

    // OTP imleci ve sayaç süresiz animasyon çalıştırdığı için pumpAndSettle
    // kullanılamaz; asset'lerin çözülmesi için gerçek async ile bekliyoruz.
    await tester.runAsync(() async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 60));
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
    });
  }

  // `loggedIn`: login ve sms ekranları oturum AÇILMADAN görülür; router
  // oturumluyken bunları ana sayfaya yönlendiriyor. Diğerleri giriş
  // sonrası akışın parçası, oturum gerektiriyor.
  final cases = <String, (String, Object?, bool)>{
    'login': (Routes.login, null, false),
    'sms-verification': (
      Routes.smsVerification,
      const SmsVerificationArgs(
        identifier: '+90 532 123 45 48',
        maskedPhone: '+90 532 *** ** 48',
      ),
      false,
    ),
    'welcome': (Routes.welcome, null, true),
    'institution-match': (Routes.institutionMatch, null, true),
    'interest-selection': (Routes.interestSelection, null, true),
    'verification-error': (Routes.verificationError, '+90 532 *** ** 48', false),
  };

  cases.forEach((name, spec) {
    testWidgets('$name render', (tester) async {
      final (location, extra, loggedIn) = spec;
      await pumpRoute(tester, location, extra: extra, loggedIn: loggedIn);
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile('goldens/auth-$name.png'),
      );
    });
  });
}
