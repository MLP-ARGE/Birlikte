// Alt navigasyonun native tab bar gibi davrandığını doğrular: sekme
// değişiminde push/pop geçiş animasyonu olmaz ve her sekme kendi durumunu
// (scroll konumu) korur.
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

  testWidgets('sekme değişimi animasyonsuz ve scroll korunuyor', (
    tester,
  ) async {
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

    // Splash'ın yönlendirme zamanlayıcısını boşalt (aksi halde disposed
    // widget'ın bekleyen Timer'ı test sonunda assertion patlatır), sonra
    // doğrudan home'a git (onboarding/login akışını atlıyoruz).
    await tester.pump(const Duration(milliseconds: 1300));
    container.read(routerProvider).go('/home');
    await tester.pumpAndSettle();

    expect(find.text('Ana Sayfa'), findsOneWidget);
    // "Sana Özel" en üstte görünür — henüz kaydırılmadı.
    expect(find.text('Sana Özel'), findsOneWidget);

    // Ana sayfayı öyle kaydır ki "Sana Özel" ekran dışına çıksın.
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Sana Özel'), findsNothing);

    // Cüzdanım sekmesine geç (henüz iskele) — bir `pump()` yetmeli,
    // push/pop animasyonu yok; native tab bar'da olduğu gibi anında sekme
    // değişir.
    await tester.tap(find.text('Cüzdanım'));
    await tester.pump();
    expect(find.text('Bu bölüm henüz hazır değil.'), findsOneWidget);
    // Home'un içeriği artık ağaçta olmamalı (IndexedStack diğer dallar
    // gizli tutuyor ama sadece aktif olanı render ediyor değil, hepsi
    // Offstage değil — asıl kontrol scroll korunumu, altta doğrulanıyor).

    // Ana Sayfa'ya geri dön — "Sana Özel" hâlâ görünmemeli (scroll korunmuş).
    await tester.tap(find.text('Ana Sayfa'));
    await tester.pump();
    expect(find.text('Ana Sayfa'), findsOneWidget);
    expect(find.text('Sana Özel'), findsNothing);
  });
}
