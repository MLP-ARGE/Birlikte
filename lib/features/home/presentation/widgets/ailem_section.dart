import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/birlikte_section_header.dart';
import '../../domain/home_models.dart';

/// "Ailem" bölümü (Figma: `ailem-section` 205:464).
///
/// Yakın ekleme akışı henüz yok (bkz. eski `_AddRow`) — ölü bir düğme
/// bırakmaktansa bölüm yalnızca mevcut yakınları listeliyor.
class AilemSection extends StatelessWidget {
  const AilemSection({super.key, required this.members, this.onMemberTap});

  final List<FamilyMember> members;
  final ValueChanged<FamilyMember>? onMemberTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BirlikteSectionHeader(title: 'Ailem'),
        const SizedBox(height: 14),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            children: [
              if (members.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s5,
                    vertical: AppSpacing.s6,
                  ),
                  child: Text(
                    'Henüz yakın eklenmedi.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              for (final (i, member) in members.indexed) ...[
                if (i > 0) const _RowDivider(),
                _MemberRow(
                  member: member,
                  onTap: onMemberTap == null
                      ? null
                      : () => onMemberTap!(member),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    thickness: 1,
    color: AppColors.borderDefault,
  );
}

/// Figma: satır iç boşluğu yatay 16 / dikey 14, gap 14; avatar 40.
const _rowPadding = EdgeInsets.symmetric(
  horizontal: AppSpacing.s5,
  vertical: 14,
);
const _avatarSize = 40.0;
const _rowGap = 14.0;

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.onTap});

  final FamilyMember member;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: _rowPadding,
        child: Row(
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surfaceSunken,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: _avatarSize,
                child: Center(
                  child: Text(
                    member.initials,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: _rowGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  // Figma: info gap 2.
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    member.relation,
                    style: AppTypography.caption.copyWith(
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
