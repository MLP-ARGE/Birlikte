// Bildirimler ekranının gerçek etkileşimini doğrular: zil rozetinden açılış,
// hedefli bir bildirime dokununca okundu işaretleyip ilgili yere gitme,
// hedefsiz bir bildirimi yerinde okundu işaretleme, tekli silme ve "Tümünü
// sil" akışı.
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

  Future<ProviderContainer> pumpApp(WidgetTester tester, {String? at}) async {
    tester.view.physicalSize = const Size(390 * 3, 1300 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: testOverrides());
    addTearDown(container.dispose);
    final router = container.read(routerProvider)..go(at ?? Routes.home);

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
    return container;
  }

  testWidgets('zil rozetinden açılır, okunmamışlar işaretli listelenir', (
    tester,
  ) async {
    await pumpApp(tester);

    // Ana sayfadaki zil "Okunmamış bildirim var" semantiğiyle rozetli.
    expect(find.bySemanticsLabel('Okunmamış bildirim var'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Okunmamış bildirim var'));
    await tester.pumpAndSettle();

    expect(find.text('Bildirimler'), findsOneWidget);
    expect(find.text('Yeni kampanya'), findsOneWidget);
    expect(find.text('Hoş geldin'), findsOneWidget);
    expect(find.text('Puan kazandın'), findsOneWidget);
    // İki okunmamış var, en az biri okundu yapılabilir durumda.
    expect(find.text('Hepsini okundu yap'), findsOneWidget);
  });

  testWidgets('hedefsiz bildirime dokununca yerinde okundu işaretlenir', (
    tester,
  ) async {
    await pumpApp(tester, at: Routes.notifications);

    expect(find.text('Hepsini okundu yap'), findsOneWidget);

    // "Puan kazandın" okunmamış ve hedefsiz — dokununca sayfadan ayrılmadan
    // okundu işaretlenmeli.
    await tester.tap(find.text('Puan kazandın'));
    await tester.pumpAndSettle();

    expect(find.text('Bildirimler'), findsOneWidget);
    // Tek okunmamış (kampanya hedefli) kaldı, buton hâlâ görünür.
    expect(find.text('Hepsini okundu yap'), findsOneWidget);
  });

  testWidgets('kampanya hedefli bildirime dokununca kampanya detayına gider', (
    tester,
  ) async {
    await pumpApp(tester, at: Routes.notifications);

    await tester.tap(find.text('Yeni kampanya'));
    await tester.pumpAndSettle();

    expect(find.text('Yüksek Lisans Fırsatı %50 İndirimli'), findsOneWidget);
  });

  testWidgets('tekli silme listeden kaldırır', (tester) async {
    await pumpApp(tester, at: Routes.notifications);

    expect(find.text('Yeni kampanya'), findsOneWidget);

    // Liste yeni → eski geldiği sırayla render edilir; ilk silme düğmesi
    // ilk satıra ("Yeni kampanya") ait.
    await tester.tap(find.bySemanticsLabel('Bildirimi sil').first);
    await tester.pumpAndSettle();

    expect(find.text('Yeni kampanya'), findsNothing);
    expect(find.text('Hoş geldin'), findsOneWidget);
  });

  testWidgets('tümünü sil onay ister ve boş durumu gösterir', (tester) async {
    await pumpApp(tester, at: Routes.notifications);

    await tester.tap(find.text('Tümünü sil'));
    await tester.pumpAndSettle();

    expect(find.text('Tüm bildirimleri sil'), findsOneWidget);
    await tester.tap(find.text('Tümünü sil').last);
    await tester.pumpAndSettle();

    expect(find.text('Şu anda bildirimin yok.'), findsOneWidget);
  });
}
