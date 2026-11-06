import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_institutions.dart';
import '../../campaigns/data/campaign_repository.dart';
import '../../campaigns/data/favorites_repository.dart';
import '../data/home_repository.dart';
import '../domain/home_models.dart';

/// Puan özeti — birlikte-api `/api/me/puan`'ın alan adları doğrulanana kadar
/// sıfır dönüyor (bkz. `HomeRepository` üstündeki not).
final pointsSummaryAsyncProvider = FutureProvider<PointsSummary>((ref) async {
  return ref.watch(homeRepositoryProvider).fetchPoints();
});

/// Ekranların senkron kullandığı görünüm; veri gelene kadar sıfır.
final pointsSummaryProvider = Provider<PointsSummary>(
  (ref) =>
      ref.watch(pointsSummaryAsyncProvider).value ??
      const PointsSummary(total: 0, usable: 0, pending: 0),
);

/// Tüm kampanyalar — Kampanyalar sekmesinin ana listesi. Diğer bölümler
/// (ana sayfa karuseli, "Sana Özel") bu listeden türetiliyor; tek kaynak
/// burada, aksi halde aynı kampanya iki ayrı id ile ekranlar arası tutarsız
/// düşerdi.
///
/// birlikte-api zaten yalnızca kullanıcıya uygun (kurum, kayıt tipi,
/// cinsiyet, tarih kurallarına uyan) kampanyaları döndürüyor; istemci ayrıca
/// filtrelemiyor.
final campaignsAsyncProvider = FutureProvider<List<Campaign>>((ref) async {
  return ref.watch(campaignRepositoryProvider).fetchAll();
});

/// Ekranların senkron kullandığı görünüm; veri gelene kadar boş liste.
final campaignsProvider = Provider<List<Campaign>>(
  (ref) => ref.watch(campaignsAsyncProvider).value ?? const [],
);

/// Tek bir kampanyayı id ile bulur — detay ekranı bunu kullanır.
final campaignByIdProvider = Provider.family<Campaign?, String>(
  (ref, id) {
    for (final c in ref.watch(campaignsProvider)) {
      if (c.id == id) return c;
    }
    return null;
  },
);

/// Ana sayfa "Kampanyalar" karuseli — tüm kampanyalardan süresi en yakın
/// olan ilk 4'ü. Ayrı bir liste olarak tutulmuyor: aksi halde aynı kampanya
/// home'da ve Kampanyalar sekmesinde farklı id'lerle düşer.
final endingSoonCampaignsProvider = Provider<List<Campaign>>((ref) {
  final all = [...ref.watch(campaignsProvider)]
    ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
  return all.take(4).toList();
});

final promoOffersProvider = Provider<List<PromoOffer>>(
  (ref) => const [
    PromoOffer(
      title: 'Ücretsiz psikolog seansı',
      subtitle: 'Yılda 6 online görüşme',
      campaignId: 'mlpcare-psikolog',
    ),
    PromoOffer(
      title: "Liv Koleji'nde %50",
      subtitle: 'Çalışan çocuklarına özel',
      campaignId: 'liv-koleji-egitim',
    ),
  ],
);

/// Favoriye eklenen kampanyaların `kampanyaGuid` değerleri.
///
/// birlikte-api'de favori/yer imi ucu yok; bu yüzden favoriler yalnızca bu
/// cihazda tutuluyor (bkz. `FavoritesRepository`) — sunucuyla senkronize
/// olmuyor, telefon değişirse sıfırlanır.
final favoriteCampaignIdsProvider =
    AsyncNotifierProvider<FavoriteCampaignIds, Set<String>>(
      FavoriteCampaignIds.new,
    );

class FavoriteCampaignIds extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() => ref.watch(favoritesRepositoryProvider).fetchIds();

  Future<void> toggle(String id) async {
    // İlk yükleme bitmeden dokunulursa, aşağıdaki iyimser güncelleme
    // sonradan gelen `build()` sonucu tarafından ezilirdi. `future`
    // beklemek bu yarışı kapatıyor.
    final current = await future;
    final adding = !current.contains(id);

    // Parantezler şart: `..` kaskadının önceliği koşullu ifadeden düşük,
    // parantezsiz yazımda `(adding ? A : B)..remove(id)` olarak
    // ayrıştırılıyor ve az önce eklenen öğe hemen siliniyordu.
    final next = adding ? {...current, id} : ({...current}..remove(id));
    state = AsyncData(next);
    await ref.read(favoritesRepositoryProvider).save(next);
  }
}

/// Senkron görünüm (kartlar bunu okuyor).
final favoriteSlugsProvider = Provider<Set<String>>(
  (ref) => ref.watch(favoriteCampaignIdsProvider).value ?? const {},
);

/// Açık kan talepleri — birlikte-api `/api/kan-talepleri`'nin alan adları
/// doğrulanana kadar boş dönüyor (bkz. `HomeRepository` üstündeki not).
final bloodRequestsAsyncProvider =
    FutureProvider<List<BloodRequest>>((ref) async {
  return ref.watch(homeRepositoryProvider).fetchBloodRequests();
});

final bloodRequestsProvider = Provider<List<BloodRequest>>(
  (ref) => ref.watch(bloodRequestsAsyncProvider).value ?? const [],
);

/// Kullanıcının kuponları — birlikte-api `/api/me/kuponlar`'ın alan adları
/// doğrulanana kadar boş dönüyor (bkz. `HomeRepository` üstündeki not).
final couponsAsyncProvider = FutureProvider<List<UserCoupon>>((ref) async {
  return ref.watch(homeRepositoryProvider).fetchCoupons();
});

/// Kullanıcının yakınları — birlikte-api `/api/me/yakinlar`'dan.
final familyMembersAsyncProvider =
    FutureProvider<List<FamilyMember>>((ref) async {
  return ref.watch(homeRepositoryProvider).fetchFamilyMembers();
});

final familyMembersProvider = Provider<List<FamilyMember>>(
  (ref) => ref.watch(familyMembersAsyncProvider).value ?? const [],
);

/// Eklenebilecek azami yakın sayısı.
final familyCapacityProvider = Provider<int>((ref) => 3);

/// Kampanyalarda kurum belirtilmediğinde gösterilecek kapsam etiketi için
/// yardımcı — enum'a bağlı olmadığını belli etmek adına ayrı tutuldu.
const allInstitutionsLabel = 'Tüm kurumlara özel';

/// Kurumların tamamı — kampanya filtrelerinde kullanılacak.
const allInstitutions = Institution.values;
