import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/birlikte_app_bar.dart';
import '../../../shared/widgets/birlikte_button.dart';
import '../../../shared/widgets/birlikte_info_card.dart';
import '../../../shared/widgets/birlikte_status_badge.dart';
import '../application/verified_profile_provider.dart';
import '../domain/verified_profile.dart';

/// Kurum eşleştirme onayı (Figma: `institution-match` 3:1787).
class InstitutionMatchPage extends ConsumerWidget {
  const InstitutionMatchPage({super.key});

  /// Figma `content`: pt 8; rozet-başlık 16, başlık-kart 28, kart-info 16.
  static const _contentTop = 8.0;
  static const _afterBadge = AppSpacing.s5;
  static const _afterHeading = 28.0;
  static const _bottomInset = 28.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(verifiedProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            BirlikteAppBar(
              onBack: context.canPop() ? context.pop : null,
              onClose: () => context.go(Routes.login),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  _contentTop,
                  AppSpacing.screenH,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BirlikteStatusBadge(
                      label: 'Kayıtların bulundu',
                      status: BirlikteStatus.success,
                    ),
                    const SizedBox(height: _afterBadge),
                    Text(
                      'Kurumun\ndoğru mu?',
                      style: AppTypography.display,
                    ),
                    // Figma: heading gap 12.
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'Bordro kayıtlarından gelen bilgiler aşağıda. Doğruysa '
                      'devam edelim.',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: _afterHeading),
                    _MatchCard(profile: profile),
                    const SizedBox(height: AppSpacing.s5),
                    const BirlikteInfoCard(
                      message: 'Kurum bilgin yanlışsa İnsan Kaynakları ile '
                          'iletişime geçmen gerekiyor.',
                    ),
                  ],
                ),
              ),
            ),
            // Figma: actions VERT gap 12, safe-area 28.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.s5,
                AppSpacing.screenH,
                _bottomInset,
              ),
              child: Column(
                children: [
                  BirlikteButton(
                    label: 'Evet, doğru',
                    onPressed: () => context.push(Routes.interestSelection),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  BirlikteButton(
                    label: 'Bilgilerim yanlış',
                    style: BirlikteButtonStyle.secondary,
                    // Figma prototipi bu düğmeyi welcome-screen'e bağlıyor;
                    // akışta welcome bir önceki adım olduğu için geri dönüş
                    // olarak yorumlandı. Derin bağlantıyla gelindiğinde yığın
                    // boş olabilir, o durumda welcome'a gidilir.
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(Routes.welcome),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bordro kaydı kartı (Figma: `identity-card` 192:76 — radius 16,
/// `surfaceSubtle` zemin; marka satırı + ayraç + üç detay satırı).
class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.profile});

  final VerifiedProfile profile;

  static const _tileSize = 56.0;
  static const _brandPad = 18.0;

  @override
  Widget build(BuildContext context) {
    final institution = profile.institution;
    final rows = <(String, String)>[
      ('Çalışan no', profile.employeeNo),
      ('Departman', profile.department),
      (
        'Eşleşme tarihi',
        DateFormat.yMMMMd('tr_TR').format(profile.matchedAt),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(_brandPad),
            child: Row(
              children: [
                Container(
                  width: _tileSize,
                  height: _tileSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: institution.color,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    institution.initials,
                    style: AppTypography.h4.copyWith(
                      color: AppColors.textOnBrand,
                    ),
                  ),
                ),
                // Figma: brand-row gap 14.
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        institution.label,
                        style: AppTypography.h4.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      // Figma: brand-text gap 3.
                      const SizedBox(height: 3),
                      Text(
                        profile.facility,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
          Padding(
            // Figma `details`: yatay 18, üst 4, alt 8.
            padding: const EdgeInsets.fromLTRB(_brandPad, 4, _brandPad, 8),
            child: Column(
              children: [
                for (final (i, (label, value)) in rows.indexed) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.borderDefault,
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.s4,
                    ),
                    child: Row(
                      children: [
                        Text(
                          label,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          value,
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
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
