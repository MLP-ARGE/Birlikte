// Router korumasının oturum durumunu TAZE okuduğunu doğrular.
//
// Regresyon: koruma önbelleklenmiş bir provider değeri okuduğunda, oturum
// kurulduktan hemen sonra yapılan gezinme "oturum yok" görüp kullanıcıyı
// login'e geri atıyordu — kullanıcı kodu giriyor ve başa dönüyordu.
import 'dart:async';

import 'package:birlikte/app/router.dart';
import 'package:birlikte/app/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';
import 'helpers/test_supabase.dart';

void main() {
  setUpAll(initSupabaseForTests);

  testWidgets('oturum kurulur kurulmaz korumalı rotaya geçilebilir', (
    tester,
  ) async {
    // Oturum durumu test sırasında değişiyor; koruma her çağrıldığında
    // güncel değeri okumalı.
    var hasSession = false;

    final container = ProviderContainer(
      overrides: testOverrides(sessionCheck: () => hasSession),
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    // Oturumsuzken korumalı rota login'e düşmeli.
    router.go(Routes.welcome);
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, Routes.login);

    // Oturum kuruldu; ARADA HİÇ FRAME BEKLEMEDEN gezinme yapılıyor —
    // gerçek akışta `setSession()` döner dönmez olan tam olarak bu.
    hasSession = true;
    unawaited(router.push(Routes.welcome));
    await tester.pumpAndSettle();

    expect(
      router.state.matchedLocation,
      Routes.welcome,
      reason: 'oturum kurulduktan hemen sonra korumalı rotaya geçilemedi',
    );
  });
}
