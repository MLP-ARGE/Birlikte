import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/birlikte_api/birlikte_api_client.dart';
import '../domain/home_models.dart';

/// Ana sayfadaki puan, kan talebi, kupon ve aile bölümlerinin veri kaynağı.
///
/// Aile (yakınlar) birlikte-api'den geliyor (`GET /api/me/yakinlar`, alan
/// adları doğrulandı). Puan (`/api/me/puan`), kuponlar (`/api/me/kuponlar`)
/// ve kan bağışı (`/api/kan-talepleri`) uçları da birlikte-api'de var ama
/// yanıt gövdelerinin tam alan adları henüz doğrulanmadı (kampanya/ilgi
/// alanı uçlarında olduğu gibi örnek JSON paylaşılmadı) — yanlış alan adıyla
/// para/puan/sağlık verisini sessizce yanlış göstermek riskli olduğundan, bu
/// üçü doğrulanana kadar boş/sıfır dönüyor ve ilgili bölümler kendi boş
/// durumlarını gösteriyor.
class HomeRepository {
  const HomeRepository(this._api);

  final BirlikteApiClient _api;

  Future<PointsSummary> fetchPoints() async {
    return const PointsSummary(total: 0, usable: 0, pending: 0);
  }

  Future<List<BloodRequest>> fetchBloodRequests({int limit = 5}) async {
    return const [];
  }

  Future<List<UserCoupon>> fetchCoupons() async {
    return const [];
  }

  /// Kullanıcının yakınları — yalnızca aktif kayıtlar.
  Future<List<FamilyMember>> fetchFamilyMembers() async {
    final rows = (await _api.yakinlar()).cast<Map<String, dynamic>>();
    return [
      for (final r in rows)
        if (r['durum'] == 'AKTIF')
          FamilyMember(
            name:
                '${(r['ad'] as String?) ?? ''} ${(r['soyad'] as String?) ?? ''}'
                    .trim(),
            relation: _relationLabel(r['yakinlikDerecesi'] as String?),
          ),
    ];
  }

  /// Bilinen kodlar dışında kalanı olduğu gibi gösteriyoruz — kataloğun tam
  /// listesi henüz paylaşılmadı, bilinmeyen bir kodu gizlemek yerine ham
  /// hâliyle göstermek daha az yanıltıcı.
  static String _relationLabel(String? kod) => switch (kod) {
    'ES' => 'Eş',
    'COCUK' => 'Çocuk',
    'ANNE' => 'Anne',
    'BABA' => 'Baba',
    null => '',
    _ => kod,
  };
}

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepository(ref.watch(birlikteApiClientProvider)),
);
