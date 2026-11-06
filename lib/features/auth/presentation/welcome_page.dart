import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/app_config/app_open_tracker.dart';
import '../../../core/push/push_notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/birlikte_app_bar.dart';
import '../../../shared/widgets/birlikte_avatar.dart';
import '../../../shared/widgets/birlikte_button.dart';
import '../../../shared/widgets/birlikte_checkbox.dart';
import '../../../shared/widgets/birlikte_institution_badge.dart';
import '../../home/presentation/widgets/missing_info_sheet.dart';
import '../application/verified_profile_provider.dart';
import '../data/profile_repository.dart';
import '../domain/verified_profile.dart';
import 'kvkk_popup.dart';

/// Karşılama ekranı (Figma: `welcome-screen` 3:160 boş, 199:2307 onaylı).
///
/// Şartlar kabul edilene kadar "Uygulamaya Başla" pasif.
class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  bool _accepted = false;
  bool _startingSending = false;

  /// Figma `content`: pt 24. Avatar-başlık 24, başlık-kart 28, kart-buton 16.
  static const _contentTop = 24.0;
  static const _afterAvatar = 24.0;
  static const _afterHeading = 28.0;
  static const _bottomInset = 28.0;

  /// Onay kutusu işaretlenince (yalnızca işaretlenirken, kaldırılırken
  /// değil) KVKK metnini okumak isteyenler için popup açılır — ayrı bir
  /// zorunlu ekran yok, onay zaten bu kutuyla veriliyor.
  void _onAcceptedChanged(bool value) {
    setState(() => _accepted = value);
    if (value) showKvkkPopup(context, ref);
  }

  Future<void> _start() async {
    if (_startingSending) return;
    // `verifyOtp()` `kvkkOnayGerekli: true` dediyse (metin güncellenmiş,
    // yeniden onay gerekiyor) onay kutusunun işaretlenmesi burada
    // sunucuya kaydediliyor — ayrı bir KVKK ekranı/butonu yok.
    if (ref.read(pendingKvkkOnayProvider)) {
      setState(() => _startingSending = true);
      await sendKvkkOnayIfNeeded(ref);
      if (!mounted) return;
      setState(() => _startingSending = false);
    }
    if (!mounted) return;
    unawaited(context.push(Routes.institutionMatch));
  }

  @override
  Widget build(BuildContext context) {
    // Profil ilk kez burada gösteriliyor; cinsiyet/ad/soyad eksikse bir kez
    // bilgi sheet'i gösterilir — giriş engellenmez, bu yalnızca bir
    // hatırlatma (bkz. `missing_info_sheet.dart`).
    maybeShowMissingInfoSheet(context, ref, ref.watch(profileProvider).value);
    // Bildirim izni burada istenir (oturum başına bir kez); izin verilmişse
    // FCM token'ı birlikte-api'ye kaydedilir (bkz. `push_notification_service.dart`).
    ensurePushTokenSynced(ref);
    // Soğuk başlangıç açılış kaydı (`POST /api/me/acilis`) — oturum başına
    // bir kez (bkz. `app_open_tracker.dart`).
    ensureAppOpenRecorded(ref);

    final profile = ref.watch(verifiedProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            BirlikteAppBar.close(onClose: () => context.go(Routes.login)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  _contentTop,
                  AppSpacing.screenH,
                  _bottomInset,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Figma'da avatarın üstünde ve kartın altında eşit 108'lik
                    // boşluk var; iki esnek boşluk bu oranı her ekranda korur.
                    const Spacer(),
                    BirlikteAvatar(
                      name: profile.fullName,
                      imageUrl: profile.photoUrl,
                    ),
                    const SizedBox(height: _afterAvatar),
                    Text(
                      'Hoş geldin,\n${profile.firstName}',
                      style: AppTypography.display,
                    ),
                    // Figma: heading gap 12.
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'Kurum bilgilerin doğrulandı. Sana özel ayrıcalıklar '
                      'hazır.',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: _afterHeading),
                    _IdentityCard(profile: profile),
                    const Spacer(),
                    BirlikteCheckbox(
                      value: _accepted,
                      onChanged: _onAcceptedChanged,
                      label: 'MLPCARE Birlikte Kullanım Şartları ve KVKK '
                          "Aydınlatma Metni'ni okudum, kabul ediyorum.",
                    ),
                    // Figma: checkbox ile buton arası 16.
                    const SizedBox(height: AppSpacing.s5),
                    BirlikteButton(
                      label: 'Uygulamaya Başla',
                      isLoading: _startingSending,
                      onPressed: _accepted && !_startingSending
                          ? _start
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kimlik kartı (Figma: `identity-card` 191:58 — 74 yüksek, radius 16,
/// `surfaceSubtle` zemin, iç boşluk 16, gap 12).
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile});

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: AppTypography.h5.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                // Figma: info gap 4.
                const SizedBox(height: AppSpacing.s2),
                Text(
                  profile.placement,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          BirlikteInstitutionBadge(institution: profile.institution),
        ],
      ),
    );
  }
}
