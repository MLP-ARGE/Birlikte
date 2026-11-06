import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/app_config/app_config_repository.dart';
import '../../../core/birlikte_api/birlikte_session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/birlikte_button.dart';

/// Sistem bakımda (`GET /api/app/config` → `bakimModu: true`).
///
/// Giriş ekranına hiç gidilmiyor — bakım kapanana kadar kullanıcı bu tam
/// ekranda kalır, "Tekrar Dene" ile uç tekrar sorgulanır.
class MaintenancePage extends ConsumerStatefulWidget {
  const MaintenancePage({super.key, this.message});

  final String? message;

  @override
  ConsumerState<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends ConsumerState<MaintenancePage> {
  bool _checking = false;

  Future<void> _retry() async {
    setState(() => _checking = true);
    final config = await ref.read(appConfigRepositoryProvider).fetch();
    if (!mounted) return;
    setState(() => _checking = false);

    // Uç yine hata verirse ya da bakım hâlâ açıksa bu ekranda kalıyoruz —
    // yanlışlıkla bakımdaki bir sisteme girmek, bakımdan çıkmamaktan daha
    // kötü (spec: hata durumunda normal akış sadece İLK sorguda geçerli).
    if (config == null || config.bakimModu) return;

    if (!context.mounted) return;
    final hasSession = ref.read(birlikteSessionProvider);
    context.go(hasSession ? Routes.home : Routes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.statusWarningSubtle,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.wrench,
                  size: 32,
                  color: AppColors.textWarning,
                ),
              ),
              const SizedBox(height: AppSpacing.s7),
              Text(
                'Bakımdayız',
                style: AppTypography.display,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                widget.message?.isNotEmpty == true
                    ? widget.message!
                    : 'Birlikte şu anda bakımda. Kısa süre içinde tekrar '
                          'yanınızdayız.',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s7),
              BirlikteButton(
                label: _checking ? 'Kontrol ediliyor...' : 'Tekrar Dene',
                onPressed: _checking ? null : _retry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
