import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/birlikte_api/birlikte_api_client.dart';
import '../domain/notification.dart';

/// Bildirim kutusu okuma/yazma — birlikte-api `/api/me/bildirimler`
/// üzerinden.
class NotificationRepository {
  const NotificationRepository(this._api);

  final BirlikteApiClient _api;

  /// Sunucu sayfa başına en fazla 100 kayıt veriyor varsayımıyla (kampanya
  /// ucuyla aynı kalıp); kataloğun bunu aşması beklenmiyor.
  static const _pageSize = 100;
  static const _maxPages = 10;

  Future<NotificationsFeed> fetchAll() async {
    final notifications = <AppNotification>[];
    var unreadCount = 0;
    var sayfa = 1;
    while (sayfa <= _maxPages) {
      final veri = await _api.bildirimlerim(sayfa: sayfa, sayfaBoyutu: _pageSize);
      unreadCount = (veri['okunmamisSayisi'] as num?)?.toInt() ?? 0;
      final rows = (veri['bildirimler'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      notifications.addAll(rows.map(_fromRow));
      final toplam = (veri['toplamKayit'] as num?)?.toInt() ?? rows.length;
      if (notifications.length >= toplam || rows.isEmpty) break;
      sayfa++;
    }
    return NotificationsFeed(
      notifications: notifications,
      unreadCount: unreadCount,
      totalCount: notifications.length,
    );
  }

  Future<int> markRead(String bildirimGuid) =>
      _api.bildirimOkunduIsaretle(bildirimGuid);

  Future<int> markAllRead() => _api.bildirimlerinHepsiniOkunduIsaretle();

  Future<int> delete(String bildirimGuid) => _api.bildirimSil(bildirimGuid);

  Future<int> deleteAll() => _api.bildirimlerinHepsiniSil();

  static AppNotification _fromRow(Map<String, dynamic> row) => AppNotification(
    id: row['bildirimGuid'] as String,
    type: NotificationType.fromCode(row['tip'] as String?),
    title: (row['baslik'] as String?) ?? '',
    message: (row['mesaj'] as String?) ?? '',
    createdAt:
        DateTime.tryParse((row['olusturmaTarihi'] as String?) ?? '') ??
        DateTime.now(),
    read: row['okundu'] as bool? ?? false,
    readAt: DateTime.tryParse((row['okunduTarihi'] as String?) ?? ''),
    targetType: row['referansTip'] as String?,
    targetId: row['referansGuid'] as String?,
  );
}

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(birlikteApiClientProvider)),
);
