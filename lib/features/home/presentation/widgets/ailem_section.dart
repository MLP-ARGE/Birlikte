import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/birlikte_section_header.dart';
import '../../domain/home_models.dart';

/// "Ailem" bölümü (Figma: `ailem-section` 205:464).
class AilemSection extends StatelessWidget {
  const AilemSection({
    super.key,
    required this.members,
    required this.capacity,
    this.onSeeAll,
    this.onMemberTap,
    this.onAddMember,
  });

  final List<FamilyMember> members;

  /// Eklenebilecek azami yakın sayısı — Figma'da "2/3" olarak gösteriliyor.
  final int capacity;
  final VoidCallback? onSeeAll;
  final ValueChanged<FamilyMember>? onMemberTap;
  final VoidCallback? onAddMember;

  bool get _canAdd => members.length < capacity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BirlikteSectionHeader(
          title: 'Ailem',
          actionLabel: 'Üye ekle',
          onAction: onSeeAll,
        ),
        const SizedBox(height: 14),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            children: [
              for (final (i, member) in members.indexed) ...[
                if (i > 0) const _RowDivider(),
                _MemberRow(
                  member: member,
                  onTap: onMemberTap == null
                      ? null
                      : () => onMemberTap!(member),
                ),
              ],
              if (_canAdd) ...[
                const _RowDivider(),
                _AddRow(
                  count: members.length,
                  capacity: capacity,
                  onTap: onAddMember,
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

/// "Yeni yakın ekle" satırı (Figma: `add-row` 205:494).
class _AddRow extends StatelessWidget {
  const _AddRow({
    required this.count,
    required this.capacity,
    required this.onTap,
  });

  final int count;
  final int capacity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: _rowPadding,
          child: Row(
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceBrand,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: _avatarSize,
                  child: Center(
                    child: Icon(
                      AppIcons.plus,
                      size: 20,
                      color: AppColors.iconBrand,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: _rowGap),
              Expanded(
                child: Text(
                  'Yeni yakın ekle',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textBrand,
                  ),
                ),
              ),
              Text(
                '$count/$capacity',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
