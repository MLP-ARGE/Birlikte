// Router korumasının oturum durumunu TAZE okuduğunu doğrular.
//
// Eski Supabase tabanlı tasarımda koruma önbelleklenmiş bir provider değeri
// okuduğunda, oturum kurulduktan hemen sonra yapılan gezinme "oturum yok"
// görüp kullanıcıyı login'e geri atıyordu. birlikte-api geçişiyle oturum
// artık tek bir senkron Notifier (`birlikteSessionProvider`); bu test onun
// `.set()` çağrısının HEMEN sonraki bir gezinmeye yansıdığını doğruluyor —
// production'daki `verifyOtp()` de tam bunu yapıyor (ara frame beklemeden).
import 'dart:async';

import 'package:birlikte/app/router.dart';
import 'package:birlikte/app/routes.dart';
import 'package:birlikte/core/birlikte_api/birlikte_session_provider.dart';
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
    final container = ProviderContainer(
      overrides: testOverrides(loggedIn: false),
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
    // gerçek akışta verifyOtp() başarılı olur olmaz olan tam olarak bu.
    container.read(birlikteSessionProvider.notifier).set(value: true);
    unawaited(router.push(Routes.welcome));
    await tester.pumpAndSettle();

    expect(
      router.state.matchedLocation,
      Routes.welcome,
      reason: 'oturum kurulduktan hemen sonra korumalı rotaya geçilemedi',
    );
  });
}
