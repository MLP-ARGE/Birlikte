import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/birlikte_alert_dialog.dart';
import '../../auth/data/profile_repository.dart';
import '../data/notification_repository.dart';
import '../domain/notification.dart';

/// Bildirim listesi + okunmamış sayısı.
///
/// Okundu/sil işlemleri iyimser güncelleniyor (favori kampanya kalıbıyla
/// aynı): sunucu çağrısı beklenmeden liste güncellenir, gerçek
/// `okunmamisSayisi` sunucudan dönünce rozet de onunla eşleşir. Her işlemden
/// sonra `profileProvider` da invalidate edilir — ana sayfadaki zil rozeti
/// ayrı bir kaynaktan (`/api/me`) okuduğu için o da tazelenmeli.
final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, NotificationsFeed>(
      NotificationsNotifier.new,
    );

class NotificationsNotifier extends AsyncNotifier<NotificationsFeed> {
  @override
  Future<NotificationsFeed> build() {
    return ref.watch(notificationRepositoryProvider).fetchAll();
  }

  Future<void> markRead(String id) async {
    final current = await future;
    final alreadyRead = current.notifications.any(
      (n) => n.id == id && n.read,
    );
    if (alreadyRead) return;

    final unreadCount = await ref
        .read(notificationRepositoryProvider)
        .markRead(id);
    state = AsyncData(
      NotificationsFeed(
        notifications: [
          for (final n in current.notifications)
            if (n.id == id) n.markRead() else n,
        ],
        unreadCount: unreadCount,
        totalCount: current.totalCount,
      ),
    );
    ref.invalidate(profileProvider);
  }

  Future<void> markAllRead() async {
    final current = await future;
    final unreadCount = await ref
        .read(notificationRepositoryProvider)
        .markAllRead();
    state = AsyncData(
      NotificationsFeed(
        notifications: [for (final n in current.notifications) n.markRead()],
        unreadCount: unreadCount,
        totalCount: current.totalCount,
      ),
    );
    ref.invalidate(profileProvider);
  }

  Future<void> delete(String id) async {
    final current = await future;
    final unreadCount = await ref.read(notificationRepositoryProvider).delete(id);
    final remaining = current.notifications.where((n) => n.id != id).toList();
    state = AsyncData(
      NotificationsFeed(
        notifications: remaining,
        unreadCount: unreadCount,
        totalCount: remaining.length,
      ),
    );
    ref.invalidate(profileProvider);
  }

  Future<void> deleteAll() async {
    final unreadCount = await ref
        .read(notificationRepositoryProvider)
        .deleteAll();
    state = AsyncData(
      NotificationsFeed(
        notifications: const [],
        unreadCount: unreadCount,
        totalCount: 0,
      ),
    );
    ref.invalidate(profileProvider);
  }
}

/// Hata fırlatırsa (ağ hatası ya da sunucu reddi) kullanıcıya popup
/// gösterir — çağıran ekran ayrıca try/catch yazmaz.
Future<void> markNotificationRead(
  BuildContext context,
  WidgetRef ref,
  String id,
) async {
  try {
    await ref.read(notificationsProvider.notifier).markRead(id);
  } catch (e) {
    if (!context.mounted) return;
    await showBirlikteApiErrorAlert(context, e, title: 'İşlem tamamlanamadı');
  }
}

Future<void> markAllNotificationsRead(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(notificationsProvider.notifier).markAllRead();
  } catch (e) {
    if (!context.mounted) return;
    await showBirlikteApiErrorAlert(context, e, title: 'İşlem tamamlanamadı');
  }
}

Future<void> deleteNotification(
  BuildContext context,
  WidgetRef ref,
  String id,
) async {
  try {
    await ref.read(notificationsProvider.notifier).delete(id);
  } catch (e) {
    if (!context.mounted) return;
    await showBirlikteApiErrorAlert(context, e, title: 'Silinemedi');
  }
}

Future<void> deleteAllNotifications(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(notificationsProvider.notifier).deleteAll();
  } catch (e) {
    if (!context.mounted) return;
    await showBirlikteApiErrorAlert(context, e, title: 'Silinemedi');
  }
}
