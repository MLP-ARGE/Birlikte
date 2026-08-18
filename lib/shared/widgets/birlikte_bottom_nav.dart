import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_typography.dart';

/// Alt navigasyon sekmeleri (Figma: `bottom-nav` 148:389).
enum BirlikteTab {
  home(label: 'Ana Sayfa', icon: AppIcons.house, route: Routes.home),
  campaigns(
    label: 'Kampanyalar',
    icon: AppIcons.ticketPercent,
    route: Routes.campaigns,
  ),
  wallet(label: 'Cüzdanım', icon: AppIcons.wallet, route: Routes.wallet),
  kandas(label: 'Kandaş', icon: AppIcons.droplet, route: Routes.kandas),
  profile(label: 'Profil', icon: AppIcons.user, route: Routes.profile);

  const BirlikteTab({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

/// Alt navigasyon (Figma: 390x90 = sekme satırı 56 + güvenli alan 34,
/// üstte 1dp `borderDefault` çizgi).
///
/// Tasarımda aktif sekmenin ikonu **dolu**; Lucide yalnızca çizgi ikon sunuyor,
/// bu yüzden aktiflik marka rengiyle veriliyor.
class BirlikteBottomNav extends StatelessWidget {
  const BirlikteBottomNav({
    super.key,
    required this.current,
    required this.onSelected,
  });

  final BirlikteTab current;
  final ValueChanged<BirlikteTab> onSelected;

  static const _rowHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderDefault)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _rowHeight,
          child: Row(
            children: [
              for (final tab in BirlikteTab.values)
                Expanded(
                  child: _Tab(
                    tab: tab,
                    selected: tab == current,
                    onTap: () => onSelected(tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final BirlikteTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: selected ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tab.icon,
              size: 24,
              color: selected ? AppColors.iconBrand : AppColors.iconSubtle,
            ),
            // Figma: sekme içi gap 4.
            const SizedBox(height: 4),
            Text(
              tab.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: selected
                    ? AppColors.textBrand
                    : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
