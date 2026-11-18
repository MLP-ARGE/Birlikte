import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/application/home_providers.dart';
import 'birlikte_bottom_nav.dart';

/// Alt navigasyonun kabuğu (Figma: `bottom-nav` 148:389).
///
/// go_router'ın `StatefulShellRoute.indexedStack`'i ile kuruldu: her sekme
/// kendi `Navigator`'ını ve state'ini korur, aralarında geçiş yaparken
/// push/pop animasyonu oynamaz — native tab bar'ların davranışı budur.
/// Sekmeleri düz `GoRoute` olarak tanımlayıp `context.go` ile geçmek (önceki
/// hâl) her tıklamada tüm sayfayı yeniden push ediyordu.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BirlikteBottomNav(
        current: BirlikteTab.values[navigationShell.currentIndex],
        onSelected: (tab) {
          // Cüzdanım/Kampanyalar `IndexedStack`'te canlı kaldığından, tek
          // seferlik bir yenileme ekrana sonraki dönüşlerde çalışmaz —
          // sekmeye her dokunuşta sunucudan tazeliyoruz (bkz.
          // `refreshWalletData`/`refreshCampaignsData`).
          if (tab == BirlikteTab.wallet) refreshWalletData(ref);
          if (tab == BirlikteTab.campaigns) refreshCampaignsData(ref);
          navigationShell.goBranch(
            tab.index,
            // Aynı sekmeye tekrar dokunmak o sekmenin kök rotasına döner
            // (native uygulamalardaki gibi, ör. "Ana Sayfa"ya ikinci dokunuş
            // scroll'u sıfırlar).
            initialLocation: tab.index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
