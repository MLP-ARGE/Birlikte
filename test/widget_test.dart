import 'package:birlikte/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uygulama açılışta splash ekranını gösterir', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BirlikteApp()));
    await tester.pump();

    expect(find.text('Birlikte'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Splash'ın yönlendirme zamanlayıcısını boşalt, aksi hâlde test
    // "Timer is still pending" ile düşer.
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  testWidgets('splash sonrası ana ekrana geçer', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BirlikteApp()));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('İskelet hazır'), findsOneWidget);
  });
}
