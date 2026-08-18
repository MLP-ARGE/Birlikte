import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_institutions.dart';
import '../domain/home_models.dart';

/// TODO(api): aşağıdaki provider'ların hepsi Figma'daki örnek içeriği döndürüyor.
/// Servisler bağlandığında yalnızca gövdeleri değişecek; ekranlar aynı kalacak.

final pointsSummaryProvider = Provider<PointsSummary>(
  (ref) => const PointsSummary(total: 2450, usable: 2150, pending: 300),
);

final promoOffersProvider = Provider<List<PromoOffer>>(
  (ref) => const [
    PromoOffer(
      title: 'Ücretsiz psikolog seansı',
      subtitle: 'Yılda 6 online görüşme',
    ),
    PromoOffer(
      title: "Liv Koleji'nde %50",
      subtitle: 'Çalışan çocuklarına özel',
    ),
  ],
);

final endingSoonCampaignsProvider = Provider<List<Campaign>>(
  (ref) => const [
    Campaign(
      brand: 'Starbucks',
      title: "Starbucks'ta Büyük Boy İçeceklerde %25",
      discountLabel: '%25',
      daysLeft: 30,
      pointsCost: 750,
    ),
    Campaign(
      brand: 'Kärcher Türkiye',
      title: 'Kärcher Temizlik Ürünlerinde %20',
      discountLabel: '%20',
      daysLeft: 24,
    ),
  ],
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
