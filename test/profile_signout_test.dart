// Profil ekranındaki çıkış akışı: onay diyaloğu, iptal ve gerçek çıkış.
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

  testWidgets('çıkış: onay istenir, iptal edilirse oturum sürer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    // Oturum durumunu sahte auth deposu yönetiyor (gerçek akıştaki gibi):
    // signOut() çağrıldığında kendisi kapatıyor.
    final container = ProviderContainer(
      overrides: testOverrides(loggedIn: null),
    );
    addTearDown(container.dispose);
    container.read(fakeSessionProvider.notifier).set(value: true);

    final router = container.read(routerProvider)..go(Routes.profile);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light,
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

    // Çıkış düğmesi görünür olmalı.
    expect(find.text('Çıkış yap'), findsOneWidget);

    // Dokun → onay diyaloğu.
    await tester.tap(find.text('Çıkış yap'));
    await tester.pumpAndSettle();
    expect(find.textContaining('emin misin'), findsOneWidget);

    // Vazgeç → profilde kal.
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, Routes.profile);

    // Tekrar aç, bu kez onayla.
    await tester.tap(find.text('Çıkış yap'));
    await tester.pumpAndSettle();
    // Diyalogdaki onay düğmesi (başlıkla aynı metin) — sonuncusu.
    await tester.tap(find.text('Çıkış yap').last);
    await tester.pumpAndSettle();

    // Depo oturumu kapatmış ve login'e yönlenmiş olmalı.
    expect(container.read(fakeSessionProvider), isFalse);
    expect(router.state.matchedLocation, Routes.login);
  });
}
