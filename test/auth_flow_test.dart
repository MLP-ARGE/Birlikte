// Onboarding'den home'a kadar akışın uçtan uca yürüdüğünü doğrular
// (Figma prototip zinciri: 3:12 → … → home-page).
import 'package:birlikte/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('onboarding → login → sms → welcome → kurum → ilgi → home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    // OTP imleci ve geri sayım süresiz çalıştığı için pumpAndSettle yerine
    // sabit süreli pump kullanıyoruz.
    Future<void> advance([int frames = 8]) async {
      for (var i = 0; i < frames; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
    }

    await tester.pumpWidget(const ProviderScope(child: BirlikteApp()));
    // Splash 1200 ms sonra yönlendiriyor.
    await tester.pump(const Duration(milliseconds: 1300));
    await advance();

    // splash → onboarding
    expect(find.text('Atla'), findsOneWidget);

    // onboarding → login
    await tester.tap(find.text('Atla'));
    await advance();
    expect(find.text('Giriş yap'), findsOneWidget);

    // Devam, geçerli numara girilene kadar pasif.
    await tester.enterText(find.byType(TextField).first, '5321234548');
    await advance();
    expect(find.text('+90 532 123 45 48'), findsOneWidget);

    await tester.tap(find.text('Devam'));
    await advance();
    expect(find.text('Doğrulama kodu'), findsOneWidget);
    expect(
      find.text('+90 532 *** ** 48 numarasına gönderdiğimiz 6 haneli kodu gir.'),
      findsOneWidget,
    );

    // 6 hane girilince otomatik doğrulanır.
    await tester.enterText(find.byType(TextField).first, '382914');
    await advance();
    expect(find.textContaining('Hoş geldin'), findsOneWidget);

    // Şartlar kabul edilmeden buton pasif.
    await tester.tap(find.text('Uygulamaya Başla'));
    await advance(4);
    expect(find.textContaining('Hoş geldin'), findsOneWidget);

    await tester.tap(find.textContaining('okudum, kabul ediyorum'));
    await advance();
    await tester.tap(find.text('Uygulamaya Başla'));
    await advance();
    expect(find.text('Kayıtların bulundu'), findsOneWidget);
    expect(find.text('MP-984302'), findsOneWidget);

    await tester.tap(find.text('Evet, doğru'));
    await advance();
    expect(find.text('İlgi alanların neler?'), findsOneWidget);

    // En az 3 kategori seçilmeden devam edilemez.
    await tester.tap(find.text('Devam'));
    await advance(4);
    expect(find.text('İlgi alanların neler?'), findsOneWidget);

    for (final category in ['Teknoloji', 'Seyahat', 'Sinema']) {
      await tester.tap(find.text(category));
      await advance(2);
    }
    await tester.tap(find.text('Devam'));
    await advance();

    // Akışın sonu: gerçek ana sayfa.
    expect(find.text('Merhaba, Ayşe'), findsOneWidget);
    expect(find.text('Toplam puanın'), findsOneWidget);
    expect(find.text('Ana Sayfa'), findsOneWidget);
  });
}
