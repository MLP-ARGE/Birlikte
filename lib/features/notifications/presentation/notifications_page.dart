import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/birlikte_alert_dialog.dart';
import '../../../shared/widgets/birlikte_app_bar.dart';
import '../../home/application/home_providers.dart';
import '../application/notification_providers.dart';
import '../domain/notification.dart';

/// Bildirimler (zil → bu ekran). Metin sunucudan gelir, uygulamaya gömülü
/// içerik yok — bkz. `NotificationRepository`.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BirlikteAppBar(onBack: () => context.pop()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Bildirimler', style: AppTypography.h1),
                  ),
                  if (feedAsync.value case final feed? when feed.notifications.isNotEmpty) ...[
                    if (feed.unreadCount > 0)
                      TextButton(
                        onPressed: () => markAllNotificationsRead(context, ref),
                        child: const Text('Hepsini okundu yap'),
                      ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textError,
                      ),
                      onPressed: () => _confirmDeleteAll(context, ref),
                      child: const Text('Tümünü sil'),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.refresh(notificationsProvider.future),
                child: switch (feedAsync) {
                  AsyncError() => _ScrollableCenter(
                    child: _ErrorState(
                      onRetry: () => ref.refresh(notificationsProvider.future),
                    ),
                  ),
                  AsyncData(:final value) when value.notifications.isEmpty =>
                    const _ScrollableCenter(child: _Empty()),
                  AsyncData(:final value) => ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenH,
                      AppSpacing.s3,
                      AppSpacing.screenH,
                      AppSpacing.s8,
                    ),
                    itemCount: value.notifications.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.s3),
                    itemBuilder: (context, i) {
                      final notification = value.notifications[i];
                      return _NotificationTile(
                        notification: notification,
                        onTap: () => _handleTap(context, ref, notification),
                        onDelete: () =>
                            deleteNotification(context, ref, notification.id),
                      );
                    },
                  ),
                  _ => const Center(child: CircularProgressIndicator()),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    if (!notification.read) {
      await markNotificationRead(context, ref, notification.id);
    }
    if (!context.mounted) return;

    final targetId = notification.targetId;
    if (targetId == null || targetId.isEmpty) return;

    switch (notification.targetType) {
      case 'KAMPANYA':
        ref.invalidate(campaignDetailAsyncProvider(targetId));
        unawaited(context.push(Routes.campaignDetail(targetId)));
      case 'KAN_TALEBI':
        ref.invalidate(bloodRequestsAsyncProvider);
        context.go(Routes.kandas);
      case 'KUPON':
        refreshWalletData(ref);
        context.go(Routes.wallet);
    }
  }

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showBirlikteConfirm(
      context,
      title: 'Tüm bildirimleri sil',
      message: 'Bütün bildirimlerin silinsin mi? Bu işlem geri alınamaz.',
      confirmLabel: 'Tümünü sil',
      destructive: true,
    );
    if (confirmed != true || !context.mounted) return;
    await deleteAllNotifications(context, ref);
  }
}

class _ScrollableCenter extends StatelessWidget {
  const _ScrollableCenter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    );
  }
}

/// Boş kutu — uydurma bildirim göstermiyoruz, ekran kendi durumunu anlatıyor
/// (diğer boş durumlarla — Kandaş/Cüzdanım — aynı kalıp).
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.bell, size: 40, color: AppColors.iconSubtle),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Şu anda bildirimin yok.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              AppIcons.circleAlert,
              size: 40,
              color: AppColors.iconSubtle,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Bildirimler yüklenemedi. Bağlantını kontrol edip tekrar dene.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            TextButton(onPressed: onRetry, child: const Text('Tekrar dene')),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s4),
        decoration: BoxDecoration(
          color: n.read ? AppColors.surface : AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TypeIcon(type: n.type),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              (n.read
                                      ? AppTypography.labelLarge
                                      : AppTypography.h6)
                                  .copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                      if (!n.read)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(
                            top: 4,
                            left: AppSpacing.s2,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.brand,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    n.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    DateFormat('d MMMM, HH:mm', 'tr_TR').format(n.createdAt),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: 'Bildirimi sil',
              child: GestureDetector(
                onTap: onDelete,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.s1),
                  child: Icon(
                    AppIcons.close,
                    size: 18,
                    color: AppColors.iconSubtle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type});

  final NotificationType type;

  @override
  Widget build(BuildContext context) {
    final (icon, background, foreground) = switch (type) {
      NotificationType.duyuru => (
        AppIcons.megaphone,
        AppColors.statusInfoSubtle,
        AppColors.iconBrand,
      ),
      NotificationType.kampanya => (
        AppIcons.ticketPercent,
        AppColors.statusInfoSubtle,
        AppColors.iconBrand,
      ),
      NotificationType.puan => (
        AppIcons.sparkles,
        AppColors.surfaceBrandStrong,
        AppColors.textOnBrand,
      ),
      NotificationType.kupon => (
        AppIcons.ticket,
        AppColors.statusInfoSubtle,
        AppColors.iconBrand,
      ),
      NotificationType.kan => (
        AppIcons.droplet,
        AppColors.statusErrorSubtle,
        AppColors.textError,
      ),
      NotificationType.genel => (
        AppIcons.bell,
        AppColors.surfaceSunken,
        AppColors.iconDefault,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: SizedBox.square(
        dimension: 40,
        child: Center(child: Icon(icon, size: 20, color: foreground)),
      ),
    );
  }
}
