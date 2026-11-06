import 'package:birlikte/core/app_config/app_config_repository.dart';
import 'package:birlikte/core/birlikte_api/birlikte_session_provider.dart';
import 'package:birlikte/core/config/app_version_provider.dart';
import 'package:birlikte/core/theme/app_institutions.dart';
import 'package:birlikte/features/auth/application/verified_profile_provider.dart';
import 'package:birlikte/features/auth/data/communication_preferences_repository.dart';
import 'package:birlikte/features/auth/data/interest_repository.dart';
import 'package:birlikte/features/auth/data/profile_repository.dart';
import 'package:birlikte/features/auth/domain/interest_category.dart';
import 'package:birlikte/features/auth/domain/verified_profile.dart';
import 'package:birlikte/features/auth/data/birlikte_auth_repository.dart';
import 'package:birlikte/features/campaigns/data/campaign_repository.dart';
import 'package:birlikte/features/campaigns/data/favorites_repository.dart';
import 'package:birlikte/features/home/application/home_providers.dart';
import 'package:birlikte/features/home/domain/home_models.dart';
import 'package:birlikte/features/profile/data/profile_stats.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Testteki [birlikteSessionProvider] üstü — gerçek `build()` SecureStorage'a
/// (platform kanalı) dokunuyor, testte bu kanal yok. `build()` burada hiç
/// çağırmadan sabit bir başlangıç değeri veriyor; `.set()` gerçek koddaki
/// gibi çalışmaya devam ediyor (örn. FakeBirlikteAuthRepository, router
/// guard testi bunu kullanıyor).
class _TestBirlikteSession extends BirlikteSessionNotifier {
  _TestBirlikteSession(this._initial);

  final bool _initial;

  @override
  bool build() => _initial;
}

/// Ağa çıkmayan giriş akışı.
///
/// Gerçek uçlar birlikte-api'de (doğrudan çağrılıyor); testte yalnızca
/// sözleşmeler taklit ediliyor: doğru kod '145823'.
class FakeBirlikteAuthRepository implements BirlikteAuthRepository {
  FakeBirlikteAuthRepository(this._ref);

  final Ref _ref;

  static const validCode = '145823';

  static const validTc = '10000000078';
  static const validDob = '1994-04-20';
  static const smsGuid = 'test-smsguid-0001';

  @override
  Future<OtpChallenge> requestOtp({
    required String kimlikNo,
    required String dogumTarihi,
  }) async {
    if (kimlikNo != validTc || dogumTarihi != validDob) {
      throw const AuthException(AuthFailure.invalidCredentials);
    }
    return const OtpChallenge(smsGuid: smsGuid, gecerlilikSaniye: 180);
  }

  @override
  Future<VerifyResult> verifyOtp({
    required String smsGuid,
    required String code,
  }) async {
    if (code != validCode) {
      throw const AuthException(AuthFailure.invalidCode);
    }
    _ref.read(birlikteSessionProvider.notifier).set(value: true);
    return const VerifyResult(
      kvkkOnayGerekli: false,
      kapatilanCihazlar: [],
    );
  }

  @override
  Future<void> signOut() async {
    _ref.read(birlikteSessionProvider.notifier).set(value: false);
  }
}

/// Ağa çıkmayan açılış kontrolü — `GET /api/app/config`'in testte gerçek
/// bir çağrıya dönüşmesini engeller (bakım/güncelleme bu feature'ın kendi
/// testlerinde ayrıca kapsanıyor; burada "bilgi yok, normal akışa devam"
/// anlamına gelen `null` yeterli).
class _TestAppConfigRepository implements AppConfigRepository {
  const _TestAppConfigRepository();

  @override
  Future<RemoteAppConfig?> fetch() async => null;
}

/// Ağa çıkmayan iletişim tercihleri — `GET /api/me/iletisim-tercihleri`'in
/// testte gerçek bir çağrıya dönüşmesini engeller. `sorulmali: false`
/// yeterli: giriş akışı testleri izin ekranını hiç beklemeden Welcome'a
/// geçmeli (gerçek uç ulaşılamadığında da akış zaten aynı şekilde devam
/// ediyor, bkz. `continueAfterLoginConsents`).
class _TestCommunicationPreferencesRepository
    implements CommunicationPreferencesRepository {
  const _TestCommunicationPreferencesRepository();

  @override
  Future<CommunicationPreferences> fetch() async =>
      const CommunicationPreferences(sorulmali: false, tercihler: []);

  @override
  Future<CommunicationPreferences> save(
    Map<CommunicationChannel, bool> degisenler,
  ) async => const CommunicationPreferences(sorulmali: false, tercihler: []);
}

/// Testlerde kullanılan sahte kampanya deposu.
///
/// Ağa çıkmaz; `campaignsProvider` zaten `testCampaigns`'e sabitlendiği için
/// `fetchAll`/`fetchDetail` pratikte çağrılmıyor — yalnızca kupon oluşturma
/// akışının (bkz. `coupon_create_sheet.dart`) ağa çıkmadan test edilebilmesi
/// için `createCoupon` gerçek bir sahte davranış sergiliyor.
class FakeCampaignRepository implements CampaignRepository {
  const FakeCampaignRepository();

  @override
  Future<List<Campaign>> fetchAll() async => testCampaigns;

  @override
  Future<Campaign> fetchDetail(String id) async =>
      testCampaigns.firstWhere((c) => c.id == id);

  @override
  Future<CampaignCoupon> createCoupon(String id) async =>
      const CampaignCoupon(code: 'BRLKT-TEST1-TEST2', status: 'AKTIF');

  @override
  Future<void> recordClick(String id) async {}
}

/// Cihaza yazmayan, bellekte tutan favori deposu.
class _TestFavoritesRepository implements FavoritesRepository {
  _TestFavoritesRepository(Set<String>? initial) : _ids = {...?initial};

  Set<String> _ids;

  @override
  Future<Set<String>> fetchIds() async => {..._ids};

  @override
  Future<void> save(Set<String> ids) async => _ids = {...ids};
}

/// Ağa çıkmayan ilgi alanı deposu — katalog `interestCatalogProvider`
/// üzerinden doğrudan sabitleniyor, bu sınıf yalnızca `save()`'in (devam
/// düğmesi) ağa çıkmadan tamamlanmasını sağlıyor.
class _TestInterestRepository implements InterestRepository {
  const _TestInterestRepository();

  @override
  Future<List<InterestCategoryItem>> fetchCatalog() async => testInterestCatalog;

  @override
  Future<void> save(List<int> ilgiAlaniIdleri) async {}
}

/// Golden ve akış testlerinde kullanılan sabit kampanya listesi.
final testCampaigns = <Campaign>[
  const Campaign(
    id: 'istinye-yuksek-lisans',
    brand: 'İstinye Üniversitesi',
    brandType: 'Eğitim Kurumu',
    title: 'Yüksek Lisans Fırsatı %50 İndirimli',
    discountLabel: '%50',
    daysLeft: 45,
    ilgiAlanlari: [InterestTag(id: 4, kod: 'EGITIM', ad: 'Eğitim')],
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
    brand: 'Starbucks',
    brandType: 'Yeme & İçme',
    title: "Starbucks'ta Büyük Boy İçeceklerde %25 İndirim",
    discountLabel: '%25',
    daysLeft: 30,
    ilgiAlanlari: [InterestTag(id: 1, kod: 'YEME_ICME', ad: 'Yeme & İçme')],
    pointsCost: 750,
  ),
  const Campaign(
    id: 'karcher-ev-bahce',
    brand: 'Kärcher Türkiye',
    brandType: 'Ev ve Bahçe Ürünleri',
    title: "MLPCare'e Özel Kärcher Ev ve Bahçe Ürünlerinde %20 Ayrıcalık",
    discountLabel: '%20',
    daysLeft: 24,
    ilgiAlanlari: [InterestTag(id: 2, kod: 'ALISVERIS', ad: 'Alışveriş')],
  ),
  const Campaign(
    id: 'arabam-garaj',
    brand: 'arabam.com',
    brandType: 'Garaj Oto Kuaför',
    title: 'arabam Garaj Oto Kuaför Kategorisinde Net 250 TL Ayrıcalık',
    discountLabel: '250 TL',
    daysLeft: 18,
    ilgiAlanlari: [InterestTag(id: 5, kod: 'OTOMOTIV', ad: 'Otomotiv')],
  ),
  const Campaign(
    id: 'liv-koleji-egitim',
    brand: 'Liv Koleji',
    brandType: 'Eğitim Kurumu',
    title: "Liv Koleji'nde Eğitim Fırsatı %50 İndirimli",
    discountLabel: '%50',
    daysLeft: 60,
    ilgiAlanlari: [InterestTag(id: 4, kod: 'EGITIM', ad: 'Eğitim')],
  ),
  const Campaign(
    id: 'mlpcare-psikolog',
    brand: 'MLPCare',
    brandType: 'Sağlık & Wellness',
    title: "MLPCare'den Ücretsiz Psikolog Seansı",
    discountLabel: 'Ücretsiz',
    daysLeft: 90,
    ilgiAlanlari: [InterestTag(id: 3, kod: 'SAGLIK', ad: 'Sağlık')],
  ),
  const Campaign(
    id: 'dod-ikinci-el',
    brand: 'DOD',
    brandType: 'İkinci El Araç Platformu',
    title: "DOD'da İkinci El Araç Alım Satımında Komisyonsuz İşlem",
    discountLabel: 'Komisyonsuz',
    daysLeft: 12,
    ilgiAlanlari: [InterestTag(id: 5, kod: 'OTOMOTIV', ad: 'Otomotiv')],
  ),
  const Campaign(
    id: 'opet-akaryakit',
    brand: 'OPET',
    brandType: 'Akaryakıt İstasyonları',
    title: 'OPET İstasyonlarında Akaryakıtta 150 TL İndirim',
    discountLabel: '150 TL',
    daysLeft: 21,
    ilgiAlanlari: [InterestTag(id: 7, kod: 'AKARYAKIT', ad: 'Akaryakıt')],
  ),
  const Campaign(
    id: 'enuygun-seyahat',
    brand: 'EnUygun',
    brandType: 'Seyahat & Konaklama',
    title: "EnUygun'da Otel ve Araç Kiralamada %10 İndirim",
    discountLabel: '%10',
    daysLeft: 40,
    ilgiAlanlari: [InterestTag(id: 6, kod: 'SEYAHAT', ad: 'Seyahat')],
  ),
  const Campaign(
    id: 'petcity-mama',
    brand: 'Petcity',
    brandType: 'Evcil Hayvan',
    title: "Petcity'de Mama ve Aksesuar Alışverişinde %30 İndirim",
    discountLabel: '%30',
    daysLeft: 15,
    ilgiAlanlari: [InterestTag(id: 8, kod: 'EVCIL_HAYVAN', ad: 'Evcil Hayvan')],
  ),
];

/// İlgi alanı seçim ekranının test kataloğu — gerçek 13 kayıtlık kataloğun
/// yerine, akış testinin dokunduğu üç kategoriyi (Teknoloji, Seyahat,
/// Sinema) içeren küçük bir sabit küme yeterli.
final testInterestCatalog = <InterestCategoryItem>[
  const InterestCategoryItem(id: 1, kod: 'TEKNOLOJI', ad: 'Teknoloji'),
  const InterestCategoryItem(id: 2, kod: 'SEYAHAT', ad: 'Seyahat'),
  const InterestCategoryItem(id: 3, kod: 'SINEMA', ad: 'Sinema'),
  const InterestCategoryItem(id: 4, kod: 'SPOR', ad: 'Spor'),
  const InterestCategoryItem(id: 5, kod: 'SAGLIK', ad: 'Sağlık'),
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
  interestCount: 6,
);

/// Testlerin ağa çıkmadan çalışmasını sağlayan provider değiştirmeleri.
///
/// `Override` tipi flutter_riverpod'dan dışa aktarılmadığı için dönüş tipi
/// yazılamıyor; `dynamic` liste `ProviderContainer(overrides:)` ile
/// uyumlu çalışıyor.
// ignore: strict_top_level_inference, always_declare_return_types
/// [loggedIn] null verilirse oturum `false`'tan başlar ama test sırasında
/// [FakeBirlikteAuthRepository] üzerinden değişebilir (uçtan uca akış
/// için). Sabit bir değer verilirse o değere kilitlenir (tek ekran
/// render'ları için).
// ignore: strict_top_level_inference, always_declare_return_types
testOverrides({
  Set<String>? favorites,
  bool? loggedIn = true,
  List<String> missingInfo = const [],
}) {
  final profile = missingInfo.isEmpty
      ? testProfile
      : VerifiedProfile(
          fullName: testProfile.fullName,
          institution: testProfile.institution,
          region: testProfile.region,
          department: testProfile.department,
          facility: testProfile.facility,
          employeeNo: testProfile.employeeNo,
          matchedAt: testProfile.matchedAt,
          interestCount: testProfile.interestCount,
          missingInfo: missingInfo,
        );
  return [
  // Sürüm paket üst verisinden okunuyor; testte platform eklentisi yok.
  // Ezmezsek sağlayıcı boş dizeye düşer ve golden'lar cihaz/ortam farkına
  // göre değişirdi — sabitliyoruz.
  appVersionProvider.overrideWith((ref) async => '1.0.0 (1)'),
  // Splash'ın açılış kontrolü (`GET /api/app/config`) gerçek ağa/platform
  // eklentisine (PackageInfo) dokunmasın diye sabit "bilgi yok" fake'i.
  appConfigRepositoryProvider.overrideWithValue(
    const _TestAppConfigRepository(),
  ),
  communicationPreferencesRepositoryProvider.overrideWithValue(
    const _TestCommunicationPreferencesRepository(),
  ),

  // Ana sayfa ve Cüzdanım bölümleri gerçek koşulda birlikte-api'den geliyor
  // (puan/kupon/kan bağışı uçlarının alan adları henüz doğrulanmadığından
  // boş/sıfır dönüyor — bkz. `HomeRepository`). Testte ağ yok; ezmezsek
  // sağlayıcılar hata verir ve Riverpod yeniden deneme zamanlayıcısı kurup
  // "A Timer is still pending" ile testleri düşürür.
  //
  // Örnek içerik bilerek dolu: goldenlar bölümlerin dolu hâlini de
  // doğrulamalı, boş hâli ayrıca test edilebilir.
  pointsSummaryAsyncProvider.overrideWith(
    (ref) async => const PointsSummary(total: 2450, usable: 2150, pending: 300),
  ),
  bloodRequestsAsyncProvider.overrideWith(
    (ref) async => const [
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
  ),
  familyMembersAsyncProvider.overrideWith(
    (ref) async => const [
      FamilyMember(name: 'Emre Yılmaz', relation: 'Eş'),
      FamilyMember(name: 'Can Yılmaz', relation: 'Çocuk'),
    ],
  ),
  couponsAsyncProvider.overrideWith((ref) async => const <UserCoupon>[]),

  // Router koruması ve widget'lar artık aynı tek kaynağı (gerçek koddaki
  // birlikteSessionProvider) okuyor; testte gerçek build()'in SecureStorage'a
  // (platform kanalı yok) dokunmaması için başlangıç değeri sabitleniyor.
  // `.notifier.set()` hâlâ çalışıyor — FakeBirlikteAuthRepository ve
  // router_guard_test bunu kullanıyor.
  birlikteSessionProvider.overrideWith(
    () => _TestBirlikteSession(loggedIn ?? false),
  ),
  birlikteAuthRepositoryProvider.overrideWith(FakeBirlikteAuthRepository.new),
  campaignRepositoryProvider.overrideWithValue(const FakeCampaignRepository()),
  campaignsProvider.overrideWithValue(testCampaigns),
  // Favoriler artık cihaz-yerel (SharedPreferences); testte platform
  // kanalına dokunmayan bellek-içi bir depoyla değiştiriliyor.
  favoritesRepositoryProvider.overrideWithValue(
    _TestFavoritesRepository(favorites),
  ),
  interestCatalogProvider.overrideWith((ref) async => testInterestCatalog),
  interestRepositoryProvider.overrideWithValue(const _TestInterestRepository()),
  verifiedProfileProvider.overrideWithValue(profile),
  // `HomePage`/`WelcomePage` eksik bilgi sheet'i için `profileProvider`'ı
  // doğrudan okuyor; ezmezsek gerçek birlikte-api'ye çıkmaya çalışıp "Timer
  // is still pending" ile testi düşürür.
  profileProvider.overrideWith((ref) async => profile),
  // Profil sayaçları artık başka provider'lardan türetiliyor (bkz.
  // `profile_stats.dart`); testte sabit veriyle değiştiriliyor (aksi hâlde
  // alttaki sağlayıcıların tam zincirini kurmak gerekirdi).
  profileStatsProvider.overrideWith((ref) async => testProfileStats),
  ];
}

/// Figma'daki profil sayaçları.
const testProfileStats = ProfileStats(
  familyCount: 2,
  familyCapacity: 3,
  favoriteCount: 8,
  interestCount: 6,
);
