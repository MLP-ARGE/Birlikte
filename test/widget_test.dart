import 'package:birlikte/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';
import 'helpers/test_supabase.dart';

void main() {
  setUpAll(initSupabaseForTests);

  group('açılış akışı', () {
    testWidgets('splash marka kilidini gösterir', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: testOverrides(loggedIn: false),
        child: const BirlikteApp(),
      ));
      await tester.pump();

      expect(find.text('MLPCARE'), findsOneWidget);
      expect(find.text('Birlikte'), findsOneWidget);
      expect(find.text('Daha avantajlıyız'), findsOneWidget);

      // Splash'ın yönlendirme zamanlayıcısını boşalt.
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('splash sonrası onboarding açılır', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: testOverrides(loggedIn: false),
        child: const BirlikteApp(),
      ));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Dört kurum,\ntek çatı'), findsOneWidget);
      expect(find.text('Atla'), findsOneWidget);
      expect(find.text('Devam'), findsOneWidget);
    });
  });

  group('onboarding', () {
    Future<void> pumpToOnboarding(WidgetTester tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: testOverrides(loggedIn: false),
        child: const BirlikteApp(),
      ));
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    testWidgets('Devam üç slaytı sırayla ilerletir', (tester) async {
      await pumpToOnboarding(tester);

      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();
      expect(find.text('Kampanyaları keşfet,\npuan kazan'), findsOneWidget);

      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();
      expect(find.text('Kuponlarınızı Kolayca Kullanın'), findsOneWidget);
    });

    // Not: onboarding sonrası açılan geçici tema kontrol ekranında sürekli
    // dönen bir spinner var, bu yüzden pumpAndSettle yerine sabit süreli
    // pump kullanılıyor — aksi hâlde "pumpAndSettle timed out" alınır.
    testWidgets('son slayttan sonra onboarding kapanır', (tester) async {
      await pumpToOnboarding(tester);

      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Devam'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Devam'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Giriş yap'), findsOneWidget);
    });

    testWidgets('Atla onboarding’i tümden geçer', (tester) async {
      await pumpToOnboarding(tester);

      await tester.tap(find.text('Atla'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Giriş yap'), findsOneWidget);
    });
  });
}
