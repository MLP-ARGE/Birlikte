// Kampanyalar sekmesinin Figma tasarımıyla karşılaştırılması.
import 'package:birlikte/app/router.dart';
import 'package:birlikte/app/routes.dart';
import 'package:birlikte/core/theme/app_theme.dart';
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

  Future<ProviderContainer> pumpRoute(
    WidgetTester tester,
    String location,
  ) async {
    final container = ProviderContainer(overrides: testOverrides());
    addTearDown(container.dispose);
    final router = container.read(routerProvider)..go(location);

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
    await tester.runAsync(() async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 60));
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
    });
    return container;
  }

  testWidgets('kampanyalar listesi render', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1300 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await pumpRoute(tester, Routes.campaigns);

    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/campaigns-list.png'),
    );
  });

  testWidgets('kampanya detayı render (tam içerik)', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await pumpRoute(
      tester,
      Routes.campaignDetail('istinye-yuksek-lisans'),
    );

    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/campaign-detail.png'),
    );
  });

  testWidgets('kampanya detayı render (yalın içerik, sekme yok)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await pumpRoute(tester, Routes.campaignDetail('starbucks-buyuk-boy'));

    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/campaign-detail-minimal.png'),
    );
  });
}
