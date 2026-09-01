import 'package:birlikte/core/supabase/supabase_client_provider.dart';
import 'package:birlikte/core/theme/app_institutions.dart';
import 'package:birlikte/features/auth/application/verified_profile_provider.dart';
import 'package:birlikte/features/auth/domain/verified_profile.dart';
import 'package:birlikte/features/auth/data/auth_repository.dart';
import 'package:birlikte/features/campaigns/data/campaign_repository.dart';
import 'package:birlikte/features/home/application/home_providers.dart';
import 'package:birlikte/features/home/domain/home_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Testlerdeki oturum durumu. Sahte auth deposu doğrulama başarılı olunca
/// bunu true yapıyor; router koruması da bunu okuyor, böylece uçtan uca
/// akış testi giriş sonrası ekranlara geçebiliyor.
final fakeSessionProvider = NotifierProvider<FakeSession, bool>(
  FakeSession.new,
);

class FakeSession extends Notifier<bool> {
  @override
  bool build() => false;

  void set({required bool value}) => state = value;
}

/// Ağa çıkmayan giriş akışı.
///
/// Gerçek uçlar (auth-lookup / auth-verify) Edge Function'da; testte
/// yalnızca sözleşmeleri taklit ediliyor: doğru kod '145823'.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this._ref);

  final Ref _ref;

  static const validCode = '145823';

  @override
  Future<OtpChallenge> requestOtp(String identifier) async =>
      const OtpChallenge(maskedPhone: '+90 532 *** ** 48');

  @override
  Future<void> verifyOtp({
    required String identifier,
    required String code,
  }) async {
    if (code != validCode) {
      throw const AuthException(AuthFailure.invalidCode);
    }
    _ref.read(fakeSessionProvider.notifier).set(value: true);
  }

  @override
  Future<void> signOut() async {
    _ref.read(fakeSessionProvider.notifier).set(value: false);
  }
}

/// Testlerde kullanılan sahte kampanya deposu.
///
/// Ağa çıkmaz, favori değişikliklerini bellekte tutar — böylece favori
/// akışı (iyimser güncelleme, geri alma) gerçek mantıkla test edilebilir.
class FakeCampaignRepository implements CampaignRepository {
  FakeCampaignRepository({Set<String>? favorites})
    : _favorites = {...?favorites};

  final Set<String> _favorites;

  @override
  Future<List<Campaign>> fetchAll() async => testCampaigns;

  @override
  Future<Campaign?> fetchBySlug(String slug) async =>
      testCampaigns.where((c) => c.id == slug).firstOrNull;

  @override
  Future<Set<String>> fetchFavoriteIds() async => {..._favorites};

  @override
  Future<void> toggleFavorite(String campaignId, {required bool add}) async {
    final slug = testCampaigns
        .where((c) => c.remoteId == campaignId)
        .map((c) => c.id)
        .firstOrNull;
    if (slug == null) return;
    if (add) {
      _favorites.add(slug);
    } else {
      _favorites.remove(slug);
    }
  }

  @override
  Future<String> createCoupon(String campaignId) async => 'BRLKT-TEST1-TEST2';
}

/// Golden ve akış testlerinde kullanılan sabit kampanya listesi.
final testCampaigns = <Campaign>[
  const Campaign(
    id: 'istinye-yuksek-lisans',
    remoteId: 'c0000000-0000-4000-8000-000000000001',
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
      'Kontenjan sınırlıdır, başvurular başvuru sırasına göre değerlendirilir.',
    ],
    cancellationNote: 'Kayıt iptalinde indirim hakkı yeniden kullanılamaz.',
    branches: [
      CampaignBranch(
        name: 'Topkapı Kampüsü',
        distanceLabel: '4,2 km',
        address:
            'Maltepe Mah. Edirne Çırpıcı Yolu Sok. No:9, Zeytinburnu / İstanbul',
        hours: 'Hafta içi 09:00 – 18:00',
      ),
      CampaignBranch(
        name: 'Güney Kampüs — Sağlık Bilimleri',
        distanceLabel: '5,1 km',
        address: 'Cevizlibağ, Teyyareci Sami Sok. No:3, Zeytinburnu / İstanbul',
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
  const Campaign(
    id: 'starbucks-buyuk-boy',
    remoteId: 'c0000000-0000-4000-8000-000000000002',
    brand: 'Starbucks',
    brandType: 'Yeme & İçme',
    title: "Starbucks'ta Büyük Boy İçeceklerde %25 İndirim",
    discountLabel: '%25',
    daysLeft: 30,
    category: CampaignCategory.foodDrink,
    pointsCost: 750,
  ),
  const Campaign(
    id: 'karcher-ev-bahce',
    remoteId: 'c0000000-0000-4000-8000-000000000003',
    brand: 'Kärcher Türkiye',
    brandType: 'Ev ve Bahçe Ürünleri',
    title: "MLPCare'e Özel Kärcher Ev ve Bahçe Ürünlerinde %20 Ayrıcalık",
    discountLabel: '%20',
    daysLeft: 24,
    category: CampaignCategory.shopping,
  ),
  const Campaign(
    id: 'arabam-garaj',
    remoteId: 'c0000000-0000-4000-8000-000000000004',
    brand: 'arabam.com',
    brandType: 'Garaj Oto Kuaför',
    title: 'arabam Garaj Oto Kuaför Kategorisinde Net 250 TL Ayrıcalık',
    discountLabel: '250 TL',
    daysLeft: 18,
    category: CampaignCategory.automotive,
  ),
  const Campaign(
    id: 'liv-koleji-egitim',
    remoteId: 'c0000000-0000-4000-8000-000000000005',
    brand: 'Liv Koleji',
    brandType: 'Eğitim Kurumu',
    title: "Liv Koleji'nde Eğitim Fırsatı %50 İndirimli",
    discountLabel: '%50',
    daysLeft: 60,
    category: CampaignCategory.education,
  ),
  const Campaign(
    id: 'mlpcare-psikolog',
    remoteId: 'c0000000-0000-4000-8000-000000000006',
    brand: 'MLPCare',
    brandType: 'Sağlık & Wellness',
    title: "MLPCare'den Ücretsiz Psikolog Seansı",
    discountLabel: 'Ücretsiz',
    daysLeft: 90,
    category: CampaignCategory.health,
  ),
  const Campaign(
    id: 'dod-ikinci-el',
    remoteId: 'c0000000-0000-4000-8000-00000000000a',
    brand: 'DOD',
    brandType: 'İkinci El Araç Platformu',
    title: "DOD'da İkinci El Araç Alım Satımında Komisyonsuz İşlem",
    discountLabel: 'Komisyonsuz',
    daysLeft: 12,
    category: CampaignCategory.automotive,
  ),
  const Campaign(
    id: 'opet-akaryakit',
    remoteId: 'c0000000-0000-4000-8000-000000000007',
    brand: 'OPET',
    brandType: 'Akaryakıt İstasyonları',
    title: 'OPET İstasyonlarında Akaryakıtta 150 TL İndirim',
    discountLabel: '150 TL',
    daysLeft: 21,
    category: CampaignCategory.fuel,
  ),
  const Campaign(
    id: 'enuygun-seyahat',
    remoteId: 'c0000000-0000-4000-8000-000000000008',
    brand: 'EnUygun',
    brandType: 'Seyahat & Konaklama',
    title: "EnUygun'da Otel ve Araç Kiralamada %10 İndirim",
    discountLabel: '%10',
    daysLeft: 40,
    category: CampaignCategory.travel,
  ),
  const Campaign(
    id: 'petcity-mama',
    remoteId: 'c0000000-0000-4000-8000-000000000009',
    brand: 'Petcity',
    brandType: 'Evcil Hayvan',
    title: "Petcity'de Mama ve Aksesuar Alışverişinde %30 İndirim",
    discountLabel: '%30',
    daysLeft: 15,
    category: CampaignCategory.pets,
  ),
];

/// Figma'daki örnek profil.
final testProfile = VerifiedProfile(
  fullName: 'Ayşe Yılmaz',
  institution: Institution.medicalPark,
  region: 'İstanbul Bölge',
  department: 'Bilgi Teknolojileri',
  facility: 'Göztepe Hastanesi',
  employeeNo: 'MP-984302',
  matchedAt: DateTime(2026, 7, 8),
);

/// Testlerin ağa çıkmadan çalışmasını sağlayan provider değiştirmeleri.
///
/// `Override` tipi flutter_riverpod'dan dışa aktarılmadığı için dönüş tipi
/// yazılamıyor; `dynamic` liste `ProviderContainer(overrides:)` ile
/// uyumlu çalışıyor.
// ignore: strict_top_level_inference, always_declare_return_types
/// [loggedIn] null verilirse oturum durumu [fakeSessionProvider]'dan
/// gelir ve test sırasında değişebilir (uçtan uca akış için). Sabit bir
/// değer verilirse o değere kilitlenir (tek ekran render'ları için).
// ignore: strict_top_level_inference, always_declare_return_types
testOverrides({Set<String>? favorites, bool? loggedIn = true}) => [
  if (loggedIn != null)
    isLoggedInProvider.overrideWithValue(loggedIn)
  else
    isLoggedInProvider.overrideWith((ref) => ref.watch(fakeSessionProvider)),
  authRepositoryProvider.overrideWith(FakeAuthRepository.new),
  campaignRepositoryProvider.overrideWithValue(
    FakeCampaignRepository(favorites: favorites),
  ),
  campaignsProvider.overrideWithValue(testCampaigns),
  verifiedProfileProvider.overrideWithValue(testProfile),
];
