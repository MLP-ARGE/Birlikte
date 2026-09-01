import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../../core/theme/app_institutions.dart';
import '../../campaigns/data/campaign_repository.dart';
import '../domain/home_models.dart';

/// TODO(api): aşağıdaki provider'ların hepsi Figma'daki örnek içeriği döndürüyor.
/// Servisler bağlandığında yalnızca gövdeleri değişecek; ekranlar aynı kalacak.

final pointsSummaryProvider = Provider<PointsSummary>(
  (ref) => const PointsSummary(total: 2450, usable: 2150, pending: 300),
);

/// Tüm kampanyalar — Kampanyalar sekmesinin ana listesi. Diğer bölümler
/// (ana sayfa karuseli, "Sana Özel") bu listeden türetiliyor; tek kaynak
/// burada, aksi halde aynı kampanya iki ayrı id ile ekranlar arası tutarsız
/// düşerdi.
///
/// Yalnızca İstinye Üniversitesi kaydı tam editoryal içerikle geldi (Figma
/// `campaign-detail`/`campaign-terms`/`campaign-branches` 3 sekmesi buradan
/// çıkarıldı); diğerleri liste kartı için yeterli alanlarla kuruldu — detay
/// ekranı eksik bölümleri gizler.
/// Tüm kampanyalar — Supabase'den.
///
/// Görünürlük (yayında mı, kullanıcının kurumuna açık mı) RLS tarafından
/// zorlanıyor; istemci ayrıca filtrelemiyor.
final campaignsAsyncProvider = FutureProvider<List<Campaign>>((ref) async {
  ref.watch(authStateProvider);
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

/// Ana sayfa "Yakında Sona Erecek" karuseli — tüm kampanyalardan süresi en
/// yakın olan ilk 4'ü. Ayrı bir liste olarak tutulmuyor: aksi halde aynı
/// kampanya home'da ve Kampanyalar sekmesinde farklı id'lerle düşer.
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

/// Favoriye eklenen kampanyaların `slug` değerleri.
///
/// Kaynak Supabase; değişiklik yazıldıktan sonra liste yeniden çekiliyor,
/// böylece liste ve detay ekranı aynı gerçeği gösteriyor.
final favoriteCampaignIdsProvider =
    AsyncNotifierProvider<FavoriteCampaignIds, Set<String>>(
      FavoriteCampaignIds.new,
    );

class FavoriteCampaignIds extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() {
    ref.watch(authStateProvider);
    return ref.watch(campaignRepositoryProvider).fetchFavoriteIds();
  }

  Future<void> toggle(String slug) async {
    // İlk yükleme bitmeden dokunulursa, aşağıdaki iyimser güncelleme
    // sonradan gelen `build()` sonucu tarafından ezilirdi. `future`
    // beklemek bu yarışı kapatıyor.
    final current = await future;
    final adding = !current.contains(slug);

    // İyimser güncelleme: dokunuşa anında tepki versin.
    //
    // Parantezler şart: `..` kaskadının önceliği koşullu ifadeden düşük,
    // parantezsiz yazımda `(adding ? A : B)..remove(slug)` olarak
    // ayrıştırılıyor ve az önce eklenen öğe hemen siliniyordu.
    state = AsyncData(
      adding ? {...current, slug} : ({...current}..remove(slug)),
    );

    final campaign = ref
        .read(campaignsProvider)
        .where((c) => c.id == slug)
        .firstOrNull;
    final remoteId = campaign?.remoteId;
    if (remoteId == null) return;

    try {
      await ref
          .read(campaignRepositoryProvider)
          .toggleFavorite(remoteId, add: adding);
    } catch (_) {
      // Yazma başarısızsa geri al — kullanıcı yanlış duruma bakmasın.
      state = AsyncData(current);
    }
  }
}

/// Senkron görünüm (kartlar bunu okuyor).
final favoriteSlugsProvider = Provider<Set<String>>(
  (ref) => ref.watch(favoriteCampaignIdsProvider).value ?? const {},
);

final bloodRequestsProvider = Provider<List<BloodRequest>>(
  (ref) => const [
    BloodRequest(
      name: 'A. Demir',
      bloodType: 'A Rh−',
      hospital: 'Çam Sakura Şehir Hastanesi',
      urgent: true,
    ),
    BloodRequest(
      name: 'E. Kaya',
      bloodType: '0 Rh+',
      hospital: 'Liv Hospital Ulus',
    ),
  ],
);

/// Aile üyeleri ve kontenjan (Figma'da "2/3").
final familyMembersProvider = Provider<List<FamilyMember>>(
  (ref) => const [
    FamilyMember(name: 'Emre Yılmaz', relation: 'Eş'),
    FamilyMember(name: 'Can Yılmaz', relation: 'Çocuk'),
  ],
);

/// Eklenebilecek azami yakın sayısı.
final familyCapacityProvider = Provider<int>((ref) => 3);

/// Kampanyalarda kurum belirtilmediğinde gösterilecek kapsam etiketi için
/// yardımcı — enum'a bağlı olmadığını belli etmek adına ayrı tutuldu.
const allInstitutionsLabel = 'Tüm kurumlara özel';

/// Kurumların tamamı — kampanya filtrelerinde kullanılacak.
const allInstitutions = Institution.values;
