// Kampanyalar sekmesinin gerçek etkileşimini doğrular: arama, kategori
// filtresi, favori durumunun liste/detay arasında paylaşılması, kampanya
// detayına gidiş-geri dönüş ve kupon oluşturma akışı.
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

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1300 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(routerProvider)..go(Routes.campaigns);

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

  testWidgets('arama sonuçları filtreler', (tester) async {
    await pumpApp(tester);

    expect(find.text('10 aktif kampanya'), findsOneWidget);
    expect(find.text('Starbucks'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'kärcher');
    await tester.pumpAndSettle();

    expect(find.text('1 aktif kampanya'), findsOneWidget);
    expect(find.text('Starbucks'), findsNothing);
    expect(find.text('Kärcher Türkiye'), findsOneWidget);
  });

  testWidgets('kategori çipi sonuçları filtreler', (tester) async {
    await pumpApp(tester);

    // Kategori çipi yatay kaydırılabilir liste içinde; "Eğitim" başlangıçta
    // viewport+cache dışında kalabiliyor, önce kaydırıp görünür kılıyoruz.
    await tester.drag(find.byType(ListView).first, const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eğitim'));
    await tester.pumpAndSettle();

    // Eğitim: İstinye Üniversitesi + Liv Koleji.
    expect(find.text('2 aktif kampanya'), findsOneWidget);
    expect(find.text('İstinye Üniversitesi'), findsOneWidget);
    expect(find.text('Liv Koleji'), findsOneWidget);
    expect(find.text('Starbucks'), findsNothing);
  });

  testWidgets('arama sonuç vermezse boş durum gösterilir', (tester) async {
    await pumpApp(tester);

    await tester.enterText(
      find.byType(TextField).first,
      'bu-marka-yok-xyz',
    );
    await tester.pumpAndSettle();

    expect(find.text('Sonuç bulunamadı'), findsOneWidget);
  });

  testWidgets('kampanyaya girip geri dönmek listeyi korur', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Starbucks'));
    await tester.pumpAndSettle();

    expect(find.text("Starbucks'ta Büyük Boy İçeceklerde %25 İndirim"),
        findsOneWidget);
    expect(find.text('Kupon Oluştur'), findsOneWidget);
    // Bu kampanyada Koşullar/Şubeler içeriği yok, sekmeler görünmemeli.
    expect(find.text('Koşullar'), findsNothing);

    await tester.tap(find.byTooltip('Geri').first);
    await tester.pumpAndSettle();

    expect(find.text('Kampanyalar'), findsWidgets);
    expect(find.text('10 aktif kampanya'), findsOneWidget);
  });

  testWidgets('favori durumu liste ve detay arasında paylaşılır', (
    tester,
  ) async {
    await pumpApp(tester);

    final favoriteIcons = find.descendant(
      of: find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Favorilere ekle'),
      matching: find.byType(Icon),
    );
    expect(favoriteIcons, findsWidgets);

    await tester.tap(
      find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Favorilere ekle').first,
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Favorilerden çıkar'),
      findsOneWidget,
    );

    await tester.tap(find.text('İstinye Üniversitesi'));
    await tester.pumpAndSettle();

    // Detayda "Kaydet" yerine "Kaydedildi" görünmeli (favori senkron).
    expect(find.text('Kaydedildi'), findsOneWidget);
  });

  testWidgets('kupon oluşturma akışı kod üretir', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('İstinye Üniversitesi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kupon Oluştur'));
    await tester.pumpAndSettle();

    // Başlık ve birincil buton aynı metni taşıyor ("Kuponu oluştur");
    // buton her zaman sonda render edildiği için `.last` hedefleniyor.
    expect(find.text('Kuponu oluştur'), findsWidgets);
    expect(find.text('KUPON KURALLARI'), findsOneWidget);

    await tester.tap(find.text('Kuponu oluştur').last);
    await tester.pumpAndSettle();

    expect(find.text('Kuponun hazır'), findsOneWidget);
    expect(find.textContaining('BRLKT-'), findsOneWidget);

    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();

    // Diyalog kapandı, detay ekranındayız.
    expect(find.text('Kuponu oluştur'), findsNothing);
    expect(find.text('Kupon Oluştur'), findsOneWidget);
  });
}
