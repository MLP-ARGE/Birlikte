import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_institutions.dart';
import '../../../shared/widgets/birlikte_alert_dialog.dart';
import '../../campaigns/data/campaign_repository.dart';
import '../data/home_repository.dart';
import '../domain/home_models.dart';

/// Puan özeti — `/api/me/puan`'dan.
final pointsSummaryAsyncProvider = FutureProvider<PointsSummary>((ref) async {
  return ref.watch(homeRepositoryProvider).fetchPoints();
});

/// Ekranların senkron kullandığı görünüm; veri gelene kadar sıfır.
final pointsSummaryProvider = Provider<PointsSummary>(
  (ref) =>
      ref.watch(pointsSummaryAsyncProvider).value ??
      const PointsSummary(total: 0, usable: 0, pending: 0),
);

/// Puan koşulları metni — `GET /api/puan/kosullar`'dan, YÖNETİMDEN
/// değiştirilebilir, uygulamaya GÖMÜLMEZ. `autoDispose` değil (uygulamanın
/// geri kalanıyla tutarlı) — bunun yerine bu sayfaya giden HER yol
/// (`PointsTermsPage`'i açan her çağrı yeri) önce `ref.invalidate` ediyor,
/// böylece her açılışta sunucudan taze metin çekiliyor.
final pointsTermsAsyncProvider = FutureProvider<PointsTerms>((ref) {
  return ref.watch(homeRepositoryProvider).fetchPointsTerms();
});

/// Tüm (filtresiz) kampanyalar — ana sayfa karuseli, favoriler ve puan
/// bedeli gibi Kampanyalar sekmesinden BAĞIMSIZ yerlerin tek kaynağı. Sekme
/// içindeki kategori filtresi ayrı bir sunucu isteği (bkz.
/// `campaignsFeedAsyncProvider`) olduğundan burası onunla karışmaz — aksi
/// halde kullanıcı bir kategoriyi filtrelerken favori sayısı da o kategoriye
/// göre küçülürdü.
///
/// birlikte-api zaten yalnızca kullanıcıya uygun (kurum, kayıt tipi,
/// cinsiyet, tarih kurallarına uyan) kampanyaları döndürüyor; istemci ayrıca
/// filtrelemiyor.
final campaignsAsyncProvider = FutureProvider<List<Campaign>>((ref) async {
  return (await ref.watch(campaignRepositoryProvider).fetchAll()).campaigns;
});

/// Ekranların senkron kullandığı görünüm; veri gelene kadar boş liste.
final campaignsProvider = Provider<List<Campaign>>(
  (ref) => ref.watch(campaignsAsyncProvider).value ?? const [],
);

/// Kampanyalar sekmesinin SUNUCU TARAFLI filtre seçimi: tek bir ilgi alanı
/// (`ilgiAlaniId`) ya da kullanıcının seçtiği TÜM ilgi alanları
/// (`sadeceIlgili`). İkisi birbirini dışlar; "Tümü" ikisi de boş/false'tur.
class CampaignsFilter {
  const CampaignsFilter({this.ilgiAlaniId, this.sadeceIlgili = false});

  final int? ilgiAlaniId;
  final bool sadeceIlgili;

  @override
  bool operator ==(Object other) =>
      other is CampaignsFilter &&
      other.ilgiAlaniId == ilgiAlaniId &&
      other.sadeceIlgili == sadeceIlgili;

  @override
  int get hashCode => Object.hash(ilgiAlaniId, sadeceIlgili);
}

/// Kampanyalar sekmesinin o anki filtre seçimi. `IndexedStack` sayfayı canlı
/// tuttuğundan sekmeler arası geçişte korunur (normal tab davranışı) —
/// dışarıdan GİRİLEN bir ziyaret `reset()` ile sıfırlar (bkz.
/// `campaignsFilterResetProvider`).
final campaignsFilterProvider =
    NotifierProvider<CampaignsSelectedFilter, CampaignsFilter>(
      CampaignsSelectedFilter.new,
    );

class CampaignsSelectedFilter extends Notifier<CampaignsFilter> {
  @override
  CampaignsFilter build() => const CampaignsFilter();

  void selectCategory(int? ilgiAlaniId) =>
      state = CampaignsFilter(ilgiAlaniId: ilgiAlaniId);

  void selectOnlyMine() => state = const CampaignsFilter(sadeceIlgili: true);

  void reset() => state = const CampaignsFilter();
}

/// Kampanyalar sekmesinin o anki filtreye göre SUNUCUDAN gelen hali.
///
/// `veri.kampanyalar` zaten eşleşen ilgi alanları önde sıralı geliyor;
/// istemci yeniden sıralamıyor (bkz. backend notu: "mobil sıralamayı
/// değiştirmesin, geldiği sırayla göstersin") — yalnızca kullanıcının kendi
/// seçtiği sıralama (Süresi yaklaşan/En yüksek indirim) bunun üzerine
/// uygulanır, "Önerilen" seçiliyken sunucu sırası olduğu gibi kalır.
final campaignsFeedAsyncProvider = FutureProvider<CampaignsFeed>((ref) {
  final filter = ref.watch(campaignsFilterProvider);
  return ref
      .watch(campaignRepositoryProvider)
      .fetchAll(ilgiAlaniId: filter.ilgiAlaniId, sadeceIlgili: filter.sadeceIlgili);
});

/// Kampanyalar ekranına HER girişte (bottom nav dokunuşu, "Tümünü Gör",
/// hızlı erişim karosu) Cüzdanım'daki gibi sunucudan tazeler — aksi halde
/// `IndexedStack` sayfayı canlı tuttuğundan başka bir yerden değişen bir
/// kampanya (favori, kupon durumu, yeni eklenen) kullanıcı sekmeye tekrar
/// gelene kadar bayat listede kalır.
void refreshCampaignsData(WidgetRef ref) {
  ref.invalidate(campaignsAsyncProvider);
  ref.invalidate(campaignsFeedAsyncProvider);
}

/// Kampanya detayı — `GET /api/kampanyalar/{guid}`'den.
///
/// Detay ekranı eskiden listeden (`campaignsProvider`) ID'ye göre arama
/// yapıyordu; o zamanki liste ucu `kuponum`'u döndürmüyordu, bu yüzden
/// `kuponAldim` true olsa bile `kuponum` hep null kalıyor ve "Kuponumu
/// Göster" her seferinde yeniden "Kupon Al" sayfasını açıyordu. Backend
/// artık liste ucunda da `kuponum`'u döndürüyor, ama detay kendi ucundan
/// okumaya devam ediyor — ayrıca `detayUrl`/tam açıklama gibi yalnızca
/// detayda gelen alanlar da var ve autoDispose olmadığından kampanyaya her
/// girişte (bkz. çağrı yerlerindeki `ref.invalidate`) taze veri garantisi
/// tek yerden sağlanıyor.
final campaignDetailAsyncProvider = FutureProvider.family<Campaign, String>(
  (ref, id) => ref.watch(campaignRepositoryProvider).fetchDetail(id),
);

/// Ana sayfa "Kampanyalar" karuseli — tüm kampanyalardan süresi en yakın
/// olan ilk 4'ü. Ayrı bir liste olarak tutulmuyor: aksi halde aynı kampanya
/// home'da ve Kampanyalar sekmesinde farklı id'lerle düşer.
final endingSoonCampaignsProvider = Provider<List<Campaign>>((ref) {
  final all = [...ref.watch(campaignsProvider)]
    ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
  return all.take(4).toList();
});

/// Favoriye eklenen kampanyaların `kampanyaGuid` değerleri.
///
/// Artık gerçek bir sunucu ucu var (`PUT`/`DELETE
/// /api/kampanyalar/{guid}/favori`) — başlangıç kümesi kampanya listesinin
/// kendi `favori` alanından türüyor (bkz. `campaignsAsyncProvider`, tek
/// kaynak); `toggle()` iyimser günceller, sunucu isteği başarısız olursa
/// geri alır.
final favoriteCampaignIdsProvider =
    AsyncNotifierProvider<FavoriteCampaignIds, Set<String>>(
      FavoriteCampaignIds.new,
    );

class FavoriteCampaignIds extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final campaigns = await ref.watch(campaignsAsyncProvider.future);
    return campaigns.where((c) => c.favori).map((c) => c.id).toSet();
  }

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
    try {
      await ref.read(campaignRepositoryProvider).setFavorite(id, adding);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

/// Senkron görünüm (kartlar bunu okuyor).
final favoriteSlugsProvider = Provider<Set<String>>(
  (ref) => ref.watch(favoriteCampaignIdsProvider).value ?? const {},
);

/// Favori ekleme/çıkarma isteğini yapar; hata fırlatırsa (ağ hatası ya da
/// sunucu reddi) kullanıcıya popup gösterir — çağıran ekranlar
/// (`HomePage`, `CampaignsListPage`, `CampaignDetailPage`,
/// `FavoriteCampaignsPage`) ayrıca try/catch yazmaz.
Future<void> toggleCampaignFavorite(
  BuildContext context,
  WidgetRef ref,
  String campaignId,
) async {
  try {
    await ref.read(favoriteCampaignIdsProvider.notifier).toggle(campaignId);
  } catch (e) {
    if (!context.mounted) return;
    await showBirlikteApiErrorAlert(
      context,
      e,
      title: 'Favori güncellenemedi',
    );
  }
}

/// "Favori kampanyalarım" ekranı — tüm kampanya listesinden (tek kaynak)
/// favori olanlar süzülüyor; ayrı bir `/favoriler` çağrısı yapılmıyor, aksi
/// halde aynı kampanya bu listede ve Kampanyalar sekmesinde ayrı ayrı
/// yüklenip tutarsız düşebilirdi.
final favoriteCampaignsProvider = Provider<List<Campaign>>((ref) {
  final favorites = ref.watch(favoriteSlugsProvider);
  return ref
      .watch(campaignsProvider)
      .where((c) => favorites.contains(c.id))
      .toList();
});

/// Açık kan talepleri — `/api/kan-talepleri`'nden.
final bloodRequestsAsyncProvider =
    FutureProvider<List<BloodRequest>>((ref) async {
  return ref.watch(homeRepositoryProvider).fetchBloodRequests();
});

final bloodRequestsProvider = Provider<List<BloodRequest>>(
  (ref) => ref.watch(bloodRequestsAsyncProvider).value ?? const [],
);

/// Bir kan talebine başvurur/başvuruyu geri çeker ve listeyi tazeler.
/// `KandasSection`'ın "Destek ol"/"Başvurdun" düğmesi bunu çağırıyor.
Future<void> toggleBloodRequestApplication(
  WidgetRef ref,
  BloodRequest request,
) async {
  final repo = ref.read(homeRepositoryProvider);
  if (request.applied) {
    await repo.cancelBloodRequestApplication(request.id);
  } else {
    await repo.applyToBloodRequest(request.id);
  }
  ref.invalidate(bloodRequestsAsyncProvider);
}

/// Kullanıcının kuponları — `/api/me/kuponlar`'dan.
final couponsAsyncProvider = FutureProvider<List<UserCoupon>>((ref) async {
  return ref.watch(homeRepositoryProvider).fetchCoupons();
});

/// Cüzdanım ekranına HER girişte kuponları/puanı sunucudan tazeler.
///
/// `WalletPage` `IndexedStack`'te canlı kaldığından (bottom-nav sekmesi),
/// tek seferlik `initState` bazlı bir yenileme ekrana her dönüşte
/// çalışmaz — bu yüzden ekrana giden HER yol (sekme dokunuşu, hızlı
/// erişim karoları, puan kartı) buraya giderken bunu çağırıyor. Aksi
/// halde başka bir yerden (müşteri hizmetleri, kampanya süresi dolması)
/// iptal/değişen bir kupon, kullanıcı ekrana tekrar gelene kadar bayat
/// listede kalırdı.
void refreshWalletData(WidgetRef ref) {
  ref.invalidate(couponsAsyncProvider);
  ref.invalidate(pointsSummaryAsyncProvider);
}

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

/// Kampanyalar sekmesi `IndexedStack`'te canlı kaldığı için arama/sıralama/
/// kategori seçimi sekmeler arası geçişte (normal tab davranışı) korunuyor
/// — ama "Tümünü Gör" ya da hızlı erişimdeki "Kampanya" karosuyla GİRİLEN
/// bir ziyaret, önceki ziyaretten kalma filtreyle açılmamalı; kullanıcı o an
/// TÜM kampanyaları görmeyi bekliyor. `bump()` çağrıldıkça `CampaignsListPage`
/// hem kendi yerel durumunu (arama metni, sıralama) hem de sunucu filtresini
/// (`campaignsFilterProvider`) sıfırlıyor.
final campaignsFilterResetProvider =
    NotifierProvider<CampaignsFilterReset, int>(CampaignsFilterReset.new);

class CampaignsFilterReset extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

/// Kampanyalarda kurum belirtilmediğinde gösterilecek kapsam etiketi için
/// yardımcı — enum'a bağlı olmadığını belli etmek adına ayrı tutuldu.
const allInstitutionsLabel = 'Tüm kurumlara özel';

/// Kurumların tamamı — kampanya filtrelerinde kullanılacak.
const allInstitutions = Institution.values;
