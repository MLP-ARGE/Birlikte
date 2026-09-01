import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/birlikte_avatar.dart';
import '../../../shared/widgets/birlikte_institution_badge.dart';
import '../../auth/application/verified_profile_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/verified_profile.dart';
import '../data/profile_stats.dart';
import 'widgets/settings_tile.dart';

/// Profil (Figma: `profile` 3:1472).
///
/// Henüz ekranı olmayan satırlar (Kişisel bilgiler, Bildirim tercihleri,
/// yasal metinler...) dokununca kısa bir bilgi gösteriyor — ölü düğme
/// bırakmamak için. İlgili bölümler kurulunca buradan bağlanacak.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(verifiedProfileProvider);
    final stats = ref.watch(profileStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.s5,
            AppSpacing.screenH,
            AppSpacing.s8,
          ),
          children: [
            Row(
              children: [
                Expanded(child: Text('Profil', style: AppTypography.h1)),
                _NotificationButton(
                  onTap: () => _notReady(context, 'Bildirimler'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s5),
            _ProfileCard(
              profile: profile,
              onTap: () => _notReady(context, 'Kişisel bilgiler'),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Sicil No: ${profile.employeeNo} · ${profile.region}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s7),

            SettingsSection(
              title: 'HESABIM',
              children: [
                SettingsTile(
                  icon: AppIcons.user,
                  label: 'Kişisel bilgiler',
                  onTap: () => _notReady(context, 'Kişisel bilgiler'),
                ),
                SettingsTile(
                  icon: AppIcons.users,
                  label: 'Ailem',
                  value: stats.whenOrNull(
                    data: (s) => '${s.familyCount}/${s.familyCapacity}',
                  ),
                  onTap: () => _notReady(context, 'Ailem'),
                ),
                SettingsTile(
                  icon: AppIcons.heart,
                  label: 'Favori kampanyalar',
                  value: stats.whenOrNull(
                    data: (s) => '${s.favoriteCount}',
                  ),
                  onTap: () => context.go(Routes.campaigns),
                ),
                SettingsTile(
                  icon: AppIcons.star,
                  label: 'İlgi alanların',
                  value: stats.whenOrNull(
                    data: (s) => '${s.interestCount} kategori',
                  ),
                  onTap: () => _notReady(context, 'İlgi alanları'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s6),

            SettingsSection(
              title: 'UYGULAMA',
              children: [
                SettingsTile(
                  icon: AppIcons.bell,
                  label: 'Bildirim tercihleri',
                  onTap: () => _notReady(context, 'Bildirim tercihleri'),
                ),
                SettingsTile(
                  icon: AppIcons.globe,
                  label: 'Dil',
                  value: switch (profile.language) {
                    'en' => 'English',
                    _ => 'Türkçe',
                  },
                  onTap: () => _notReady(context, 'Dil seçimi'),
                ),
                SettingsTile(
                  icon: AppIcons.eye,
                  label: 'Görünüm',
                  value: switch (profile.theme) {
                    'light' => 'Açık',
                    'dark' => 'Koyu',
                    _ => 'Sistem',
                  },
                  onTap: () => _notReady(context, 'Görünüm'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s6),

            SettingsSection(
              title: 'YASAL VE DESTEK',
              children: [
                SettingsTile(
                  icon: AppIcons.help,
                  label: 'Yardım ve destek',
                  onTap: () => _notReady(context, 'Yardım ve destek'),
                ),
                SettingsTile(
                  icon: AppIcons.fileText,
                  label: 'Sık sorulan sorular',
                  onTap: () => _notReady(context, 'Sık sorulan sorular'),
                ),
                SettingsTile(
                  icon: AppIcons.shieldAlert,
                  label: 'KVKK ve açık rıza',
                  onTap: () => _notReady(context, 'KVKK metni'),
                ),
                SettingsTile(
                  icon: AppIcons.bookOpen,
                  label: 'Kullanım koşulları',
                  onTap: () => _notReady(context, 'Kullanım koşulları'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s7),

            _SignOutButton(onTap: () => _confirmSignOut(context, ref)),
            const SizedBox(height: AppSpacing.s5),
            Center(
              child: Text(
                '${AppConfig.appName} v${AppConfig.version} '
                '(${AppConfig.buildYear})',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _notReady(BuildContext context, String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what yakında eklenecek.')));
  }

  /// Çıkış geri alınamaz bir işlem; önce onay soruyoruz.
  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text('Çıkış yap', style: AppTypography.h4),
        content: Text(
          'Hesabından çıkmak istediğine emin misin? Tekrar girmek için '
          'doğrulama kodu gerekecek.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Çıkış yap',
              style: AppTypography.buttonMedium.copyWith(
                color: AppColors.textError,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(authRepositoryProvider).signOut();
    if (!context.mounted) return;
    // Yığını temizle: geri tuşu oturumlu ekranlara dönmesin.
    context.go(Routes.login);
  }
}

/// Profil kartı (Figma: avatar + ad + kurum rozeti + departman).
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, required this.onTap});

  final VerifiedProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s5),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            BirlikteAvatar(
              name: profile.fullName,
              imageUrl: profile.photoUrl,
              size: 56,
            ),
            const SizedBox(width: AppSpacing.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h4.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  BirlikteInstitutionBadge(
                    institution: profile.institution,
                    height: 20,
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    profile.department,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              AppIcons.chevronRight,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Bildirimler',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: const SizedBox.square(
          dimension: 44,
          child: Center(
            child: Icon(
              AppIcons.bell,
              size: 24,
              color: AppColors.iconDefault,
            ),
          ),
        ),
      ),
    );
  }
}

/// Çıkış düğmesi (Figma: hata renginde yumuşak zemin, pill).
class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: AppSize.buttonLarge,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.statusErrorSubtle,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                AppIcons.logOut,
                size: 20,
                color: AppColors.textError,
              ),
              const SizedBox(width: AppSpacing.s3),
              Text(
                'Çıkış yap',
                style: AppTypography.buttonLarge.copyWith(
                  color: AppColors.textError,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
