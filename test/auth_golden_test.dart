// Auth akışındaki ekranların Figma tasarımıyla karşılaştırılması.
import 'package:birlikte/app/router.dart';
import 'package:birlikte/app/routes.dart';
import 'package:birlikte/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  /// Verilen rotayı 390x844 (Figma kare ölçüsü) yüzeyde render eder.
  Future<void> pumpRoute(
    WidgetTester tester,
    String location, {
    Object? extra,
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
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

  final cases = <String, (String, Object?)>{
    'login': (Routes.login, null),
    'sms-verification': (Routes.smsVerification, '+90 532 123 45 48'),
    'welcome': (Routes.welcome, null),
    'institution-match': (Routes.institutionMatch, null),
    'interest-selection': (Routes.interestSelection, null),
    'verification-error': (Routes.verificationError, '+90 532 *** ** 48'),
  };

  cases.forEach((name, spec) {
    testWidgets('$name render', (tester) async {
      final (location, extra) = spec;
      await pumpRoute(tester, location, extra: extra);
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile('goldens/auth-$name.png'),
      );
    });
  });
}
