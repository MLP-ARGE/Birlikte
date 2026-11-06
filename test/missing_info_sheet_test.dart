// Giriş sonrası eksik bilgi bildirimini doğrular (bkz. `missing_info_sheet.dart`).
//
// Regresyon: ilk sürümde `maybeShowMissingInfoSheet`, "zaten gösterildi"
// bayrağını `build()` SIRASINDA güncelliyordu. Bu, Riverpod'un "Tried to
// modify a provider while the widget tree was building" hatasına yol açtı —
// ama testte hiç yakalanmadı, çünkü hiçbir testte profilde gerçekten eksik
// bilgi yoktu. Bu test o koşulu gerçekten kuruyor.
import 'package:birlikte/app/router.dart';
import 'package:birlikte/app/routes.dart';
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

  testWidgets(
    'ad/soyad eksikse welcome ekranında çöküş olmadan uyarı sheet\'i açılır',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer(
        overrides: testOverrides(missingInfo: const ['AD']),
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider)..go(Routes.welcome);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Bilgilerini tamamla'), findsOneWidget);
      expect(find.textContaining('kurumunla'), findsOneWidget);
    },
  );
}
