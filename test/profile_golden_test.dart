// Profil ekranının Figma tasarımıyla karşılaştırılması (`profile` 3:1472).
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

  testWidgets('profil render', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: testOverrides());
    addTearDown(container.dispose);
    final router = container.read(routerProvider)..go(Routes.profile);

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
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/profile.png'),
    );
  });
}
