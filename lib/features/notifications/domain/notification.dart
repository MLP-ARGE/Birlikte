/// Bildirim türü — ikon/renk seçimi için (Figma'da ayrı bir ekran yok, bu
/// tasarım kararı backend'in kategorilerine göre bu özellik için alındı).
enum NotificationType {
  genel,
  duyuru,
  kampanya,
  puan,
  kupon,
  kan;

  static NotificationType fromCode(String? code) => switch (code) {
    'DUYURU' => NotificationType.duyuru,
    'KAMPANYA' => NotificationType.kampanya,
    'PUAN' => NotificationType.puan,
    'KUPON' => NotificationType.kupon,
    'KAN' => NotificationType.kan,
    _ => NotificationType.genel,
  };
}

/// Tek bir bildirim — `GET /api/me/bildirimler`'den.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.read,
    this.readAt,
    this.targetType,
    this.targetId,
  });

  /// `bildirimGuid`.
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool read;
  final DateTime? readAt;

  /// `referansTip` — `KAMPANYA` | `KAN_TALEBI` | `KUPON`. Null/boşsa
  /// bildirime tıklamak yalnızca okundu işaretler, hiçbir yere götürmez.
  final String? targetType;

  /// `referansGuid`.
  final String? targetId;

  AppNotification markRead() => read
      ? this
      : AppNotification(
          id: id,
          type: type,
          title: title,
          message: message,
          createdAt: createdAt,
          read: true,
          readAt: DateTime.now(),
          targetType: targetType,
          targetId: targetId,
        );
}

/// `/api/me/bildirimler` yanıtının tamamı.
class NotificationsFeed {
  const NotificationsFeed({
    required this.notifications,
    required this.unreadCount,
    required this.totalCount,
  });

  final List<AppNotification> notifications;

  /// `okunmamisSayisi`.
  final int unreadCount;

  /// `toplamKayit`.
  final int totalCount;
}
