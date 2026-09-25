// Kategori filtresi bottom sheet'inin alt navigasyonun ÜSTÜNDE açıldığını
// doğrular.
//
// UI testi bulgusu (UI-003): sheet açıkken alt navigasyon barı karartılmadan
// görünür kalıyor ve tıklanabiliyordu. Sebebi, sekmelerin
// StatefulShellRoute.indexedStack ile kurulması: her dalın kendi Navigator'ı
// var ve sheet varsayılan olarak o dalın içinde açılıyor, dolayısıyla shell'in
// çizdiği bar sheet'in üstünde kalıyor.
//
// Bu test davranışı ölçüyor: sheet açıkken nav bar'a dokunmak sekme
// değiştirmemeli. useRootNavigator kaldırılırsa test düşer.
import 'package:birlikte/app/app.dart';
import 'package:birlikte/app/router.dart';
import 'package:flutter/material.dart';
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

  testWidgets('filtre sheet açıkken alt navigasyon devre dışı', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: testOverrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BirlikteApp(),
      ),
    );
    // Splash'ın zamanlayıcısını boşalt, sonra kampanyalar sekmesine geç.
    await tester.pump(const Duration(milliseconds: 1300));
    container.read(routerProvider).go('/kampanyalar');
    await tester.pumpAndSettle();

    expect(find.text('Kampanyalar'), findsWidgets);

    // Filtre düğmesi (arama satırının sağındaki ikon).
    await tester.tap(find.bySemanticsLabel('Filtrele'));
    await tester.pumpAndSettle();

    // Sheet açıldı.
    expect(find.text('Kategori'), findsOneWidget);

    // Nav bar'daki "Ana Sayfa" sekmesine dokun. Sheet modal olduğu için
    // dokunuş barrier tarafından yutulmalı: sekme DEĞİŞMEMELİ.
    await tester.tap(find.text('Ana Sayfa'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Hâlâ sheet açık ve hâlâ kampanyalar sekmesindeyiz.
    expect(
      find.text('Kategori'),
      findsOneWidget,
      reason: 'nav bar dokunuşu sheet üzerinden geçti',
    );
    expect(
      find.text('Merhaba, Ayşe'),
      findsNothing,
      reason: 'sheet açıkken ana sayfaya geçilmemeliydi',
    );
  });
}
