// GEÇİCİ: onboarding görsellerini başsız render edip gözle doğrulamak için.
import 'package:birlikte/core/theme/app_theme.dart';
import 'package:birlikte/features/onboarding/presentation/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('onboarding 3 slayt render', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: const OnboardingPage()),
      ),
    );

    // Asset'lerin diskten çözülmesi için gerçek async gerekiyor.
    await tester.runAsync(() async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 60));
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
    });

    for (var slide = 1; slide <= 3; slide++) {
      await expectLater(
        find.byType(OnboardingPage),
        matchesGoldenFile('goldens/onboarding-$slide.png'),
      );
      if (slide < 3) {
        await tester.tap(find.text('Devam'));
        await tester.runAsync(() async {
          for (var i = 0; i < 8; i++) {
            await tester.pump(const Duration(milliseconds: 60));
            await Future<void>.delayed(const Duration(milliseconds: 40));
          }
        });
      }
    }
  });
}
