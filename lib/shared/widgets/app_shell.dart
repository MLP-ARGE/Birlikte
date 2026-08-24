import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'birlikte_bottom_nav.dart';

/// Alt navigasyonun kabuğu (Figma: `bottom-nav` 148:389).
///
/// go_router'ın `StatefulShellRoute.indexedStack`'i ile kuruldu: her sekme
/// kendi `Navigator`'ını ve state'ini korur, aralarında geçiş yaparken
/// push/pop animasyonu oynamaz — native tab bar'ların davranışı budur.
/// Sekmeleri düz `GoRoute` olarak tanımlayıp `context.go` ile geçmek (önceki
/// hâl) her tıklamada tüm sayfayı yeniden push ediyordu.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BirlikteBottomNav(
        current: BirlikteTab.values[navigationShell.currentIndex],
        onSelected: (tab) => navigationShell.goBranch(
          tab.index,
          // Aynı sekmeye tekrar dokunmak o sekmenin kök rotasına döner
          // (native uygulamalardaki gibi, ör. "Ana Sayfa"ya ikinci dokunuş
          // scroll'u sıfırlar).
          initialLocation: tab.index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
