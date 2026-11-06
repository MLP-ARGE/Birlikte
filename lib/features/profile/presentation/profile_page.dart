import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_version_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/birlikte_alert_dialog.dart';
import '../../../shared/widgets/birlikte_avatar.dart';
import '../../../shared/widgets/birlikte_institution_badge.dart';
import '../../auth/application/verified_profile_provider.dart';
import '../../auth/data/birlikte_auth_repository.dart';
import '../../auth/domain/verified_profile.dart';
import '../data/profile_stats.dart';
import 'widgets/settings_tile.dart';

/// Profil (Figma: `profile` 3:1472).
///
/// Henüz ekranı olmayan satırlar (Kişisel bilgiler, yasal metinler...)
/// dokununca kısa bir bilgi gösteriyor — ölü düğme bırakmamak için. İlgili
/// bölümler kurulunca buradan bağlanacak.
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
            // Bildirim zili kaldırıldı: bildirim ekranı bu sürümde yok ve
            // hiçbir şey yapmayan bir düğme bırakmak istemiyoruz.
            Text('Profil', style: AppTypography.h1),
            const SizedBox(height: AppSpacing.s5),
            // Kişisel bilgiler ekranı yok; kart bilgi gösteriyor, tıklanmıyor.
            _ProfileCard(profile: profile),
            const SizedBox(height: AppSpacing.s4),
            Text(
              // PDKS bölge bilgisi vermiyor, birlikte-api sicil numarası
              // vermiyor; ikisi de boşken sarkık bir metin kalmasın diye
              // parçalar süzülüyor.
              [
                if (profile.employeeNo case final no? when no.isNotEmpty)
                  'Sicil No: $no',
                if (profile.facility.isNotEmpty) profile.facility,
                if (profile.region.isNotEmpty) profile.region,
              ].join(' · '),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s7),

            // Bu sürümde YALNIZCA çalışan öğeler gösteriliyor.
            //
            // Kişisel bilgiler, Ailem, İlgi alanların, Dil ve Görünüm
            // ekranları henüz kurulmadı; hiçbir şey yapmayan satırlar
            // Apple'ın 2.1 "App Completeness" kuralına takılıyor.
            //
            // Dil ve Görünüm özellikle dikkat istiyor: veritabanında alanları
            // var ama uygulama ne dil değiştirebiliyor ne de koyu temaya
            // geçebiliyor. Çalışır görünen ama etkisi olmayan bir ayar,
            // olmayandan daha kötü.
            SettingsSection(
              title: 'HESABIM',
              children: [
                SettingsTile(
                  icon: AppIcons.heart,
                  label: 'Favori kampanyalar',
                  value: stats.whenOrNull(data: (s) => '${s.favoriteCount}'),
                  onTap: () => context.go(Routes.campaigns),
                ),
                SettingsTile(
                  icon: AppIcons.bell,
                  label: 'Bildirim tercihleri',
                  onTap: () => context.push(Routes.communicationPreferences),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s6),

            // Adresi tanımlı olmayan satır hiç gösterilmiyor; bölümün
            // tamamı boşalırsa başlığı da çizilmiyor.
            if (_legalTiles(context).isNotEmpty) ...[
              SettingsSection(
                title: 'YASAL VE DESTEK',
                children: _legalTiles(context),
              ),
              const SizedBox(height: AppSpacing.s7),
            ],

            _SignOutButton(onTap: () => _confirmSignOut(context, ref)),
            const SizedBox(height: AppSpacing.s5),
            Center(
              child: Text(
                // Sürüm asenkron geliyor; henüz yüklenmediyse yalnızca
                // uygulama adını gösteriyoruz, satır zıplamasın diye.
                switch (ref.watch(appVersionProvider)) {
                  AsyncData(:final value) when value.isNotEmpty =>
                    '${AppConfig.appName} v$value · ${AppConfig.buildYear}',
                  _ => '${AppConfig.appName} · ${AppConfig.buildYear}',
                },
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

  /// Çıkış geri alınamaz bir işlem; önce onay soruyoruz.
  /// Yalnızca adresi tanımlı olan yasal bağlantılar.
  List<Widget> _legalTiles(BuildContext context) => [
    if (AppConfig.supportUrl.isNotEmpty)
      SettingsTile(
        icon: AppIcons.help,
        label: 'Yardım ve destek',
        onTap: () => _openUrl(context, AppConfig.supportUrl),
      ),
    if (AppConfig.privacyPolicyUrl.isNotEmpty)
      SettingsTile(
        icon: AppIcons.shieldAlert,
        label: 'KVKK ve gizlilik',
        onTap: () => _openUrl(context, AppConfig.privacyPolicyUrl),
      ),
    if (AppConfig.termsUrl.isNotEmpty)
      SettingsTile(
        icon: AppIcons.bookOpen,
        label: 'Kullanım koşulları',
        onTap: () => _openUrl(context, AppConfig.termsUrl),
      ),
  ];

  /// Bağlantıyı tarayıcıda açar. Açılamazsa kullanıcıya sessiz kalmıyoruz.
  Future<void> _openUrl(BuildContext context, String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);
    if (!ok && context.mounted) {
      await showBirlikteAlert(context, title: 'Bağlantı açılamadı');
    }
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showBirlikteConfirm(
      context,
      title: 'Çıkış yap',
      message: 'Hesabından çıkmak istediğine emin misin? Tekrar girmek için '
          'doğrulama kodu gerekecek.',
      confirmLabel: 'Çıkış yap',
      destructive: true,
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(birlikteAuthRepositoryProvider).signOut();
    if (!context.mounted) return;
    // Yığını temizle: geri tuşu oturumlu ekranlara dönmesin.
    context.go(Routes.login);
  }
}

/// Profil kartı (Figma: avatar + ad + kurum rozeti + departman).
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final VerifiedProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                if (profile.position case final position?
                    when position.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    position,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
              const Icon(AppIcons.logOut, size: 20, color: AppColors.textError),
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
