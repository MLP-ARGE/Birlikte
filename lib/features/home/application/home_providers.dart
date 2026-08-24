import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_institutions.dart';
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
final campaignsProvider = Provider<List<Campaign>>(
  (ref) => const [
    Campaign(
      id: 'istinye-yuksek-lisans',
      brand: 'İstinye Üniversitesi',
      brandType: 'Eğitim Kurumu',
      title: 'Yüksek Lisans Fırsatı %50 İndirimli',
      discountLabel: '%50',
      daysLeft: 45,
      category: CampaignCategory.education,
      description:
          'MLP Care, Medical Park, Liv Hospital ve Liv Koleji çalışanlarına '
          'İstinye Üniversitesi yüksek lisans programlarında %50 indirim. '
          'Geçerli bölümler: Bilgisayar Mühendisliği, Yapay Zeka, İşletme '
          'Yüksek Lisans.',
      validity: '1 Eylül 2026 — 31 Ocak 2027',
      tags: ['Eğitim', 'Tüm Çalışanlara Özel', 'Yüksek Lisans'],
      steps: [
        'MLPCARE Birlikte uygulamasından başvuru formunu doldur.',
        'İstinye Üniversitesi kayıt ofisine başvurunu ilet.',
        'Kayıt tamamlandıktan sonra %50 indirimli ücretle eğitime başla.',
      ],
      whoQualifies: [
        'MLP Care bünyesinde kadrolu çalışan tüm personel',
        'En az 3 ay çalışma süresini tamamlamış olanlar',
        'Çalışanın 1. derece yakınları (eş, çocuk, anne, baba)',
      ],
      rules: [
        'İndirim 2026–2027 güz ve bahar dönemi kayıtlarında geçerlidir.',
        'Diğer indirim, burs ve kampanyalarla birleştirilemez.',
        'Kupon oluşturulduktan sonra 30 gün içinde kullanılmalıdır.',
        'Her çalışan kampanya süresince bir kez yararlanabilir.',
        'Kayıt sırasında MLP Care personel kimliği ibraz edilmelidir.',
        'Kontenjan sınırlıdır, başvurular başvuru sırasına göre '
            'değerlendirilir.',
      ],
      cancellationNote:
          'Kayıt iptalinde indirim hakkı yeniden kullanılamaz.',
      branches: [
        CampaignBranch(
          name: 'Topkapı Kampüsü',
          distanceLabel: '4,2 km',
          address: 'Maltepe Mah. Edirne Çırpıcı Yolu Sok. No:9, '
              'Zeytinburnu / İstanbul',
          hours: 'Hafta içi 09:00 – 18:00',
        ),
        CampaignBranch(
          name: 'Güney Kampüs — Sağlık Bilimleri',
          distanceLabel: '5,1 km',
          address: 'Cevizlibağ, Teyyareci Sami Sok. No:3, '
              'Zeytinburnu / İstanbul',
          hours: 'Hafta içi 09:00 – 17:30',
        ),
        CampaignBranch(
          name: 'Topkapı Liv Hospital Uygulama Kampüsü',
          distanceLabel: '8,6 km',
          address: 'Kaptanpaşa Mah. Darülaceze Cad. No:25, Şişli / İstanbul',
          hours: 'Hafta içi 09:00 – 18:00',
        ),
        CampaignBranch(
          name: 'Vadistanbul Kampüsü',
          distanceLabel: '11,8 km',
          address: 'Ayazağa Mah. Azerbaycan Cad. No:3-1, Sarıyer / İstanbul',
          hours: 'Hafta içi 08:30 – 17:00',
        ),
      ],
    ),
    Campaign(
      id: 'starbucks-buyuk-boy',
      brand: 'Starbucks',
      brandType: 'Yeme & İçme',
      title: "Starbucks'ta Büyük Boy İçeceklerde %25 İndirim",
      discountLabel: '%25',
      daysLeft: 30,
      category: CampaignCategory.foodDrink,
      pointsCost: 750,
    ),
    Campaign(
      id: 'karcher-ev-bahce',
      brand: 'Kärcher Türkiye',
      brandType: 'Ev ve Bahçe Ürünleri',
      title: "MLPCare'e Özel Kärcher Ev ve Bahçe Ürünlerinde %20 Ayrıcalık",
      discountLabel: '%20',
      daysLeft: 24,
      category: CampaignCategory.shopping,
    ),
    Campaign(
      id: 'arabam-garaj',
      brand: 'arabam.com',
      brandType: 'Garaj Oto Kuaför',
      title: 'arabam Garaj Oto Kuaför Kategorisinde Net 250 TL Ayrıcalık',
      discountLabel: '250 TL',
      daysLeft: 18,
      category: CampaignCategory.automotive,
    ),
    Campaign(
      id: 'liv-koleji-egitim',
      brand: 'Liv Koleji',
      brandType: 'Eğitim Kurumu',
      title: "Liv Koleji'nde Eğitim Fırsatı %50 İndirimli",
      discountLabel: '%50',
      daysLeft: 60,
      category: CampaignCategory.education,
    ),
    Campaign(
      id: 'mlpcare-psikolog',
      brand: 'MLPCare',
      brandType: 'Sağlık & Wellness',
      title: "MLPCare'den Ücretsiz Psikolog Seansı",
      discountLabel: 'Ücretsiz',
      daysLeft: 90,
      category: CampaignCategory.health,
    ),
    Campaign(
      id: 'dod-ikinci-el',
      brand: 'DOD',
      brandType: 'İkinci El Araç Platformu',
      title: "DOD'da İkinci El Araç Alım Satımında Komisyonsuz İşlem",
      discountLabel: 'Komisyonsuz',
      daysLeft: 12,
      category: CampaignCategory.automotive,
    ),
    Campaign(
      id: 'opet-akaryakit',
      brand: 'OPET',
      brandType: 'Akaryakıt İstasyonları',
      title: 'OPET İstasyonlarında Akaryakıtta 150 TL İndirim',
      discountLabel: '150 TL',
      daysLeft: 21,
      category: CampaignCategory.fuel,
    ),
    Campaign(
      id: 'enuygun-seyahat',
      brand: 'EnUygun',
      brandType: 'Seyahat & Konaklama',
      title: "EnUygun'da Otel ve Araç Kiralamada %10 İndirim",
      discountLabel: '%10',
      daysLeft: 40,
      category: CampaignCategory.travel,
    ),
    Campaign(
      id: 'petcity-mama',
      brand: 'Petcity',
      brandType: 'Evcil Hayvan',
      title: "Petcity'de Mama ve Aksesuar Alışverişinde %30 İndirim",
      discountLabel: '%30',
      daysLeft: 15,
      category: CampaignCategory.pets,
    ),
  ],
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

/// Favoriye eklenen kampanya id'leri — kart, detay ve liste arasında ortak.
///
/// TODO(api): kullanıcı bazlı kalıcı depoya (backend veya secure storage)
/// bağlanacak; şimdilik bellekte, uygulama yeniden başlayınca sıfırlanıyor.
final favoriteCampaignIdsProvider =
    NotifierProvider<FavoriteCampaignIds, Set<String>>(FavoriteCampaignIds.new);

class FavoriteCampaignIds extends Notifier<Set<String>> {
  @override
  Set<String> build() => {
    for (final c in ref.watch(campaignsProvider))
      if (c.favorite) c.id,
  };

  void toggle(String campaignId) {
    state = {...state}..toggle(campaignId);
  }
}

extension on Set<String> {
  void toggle(String value) {
    if (!remove(value)) add(value);
  }
}

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
