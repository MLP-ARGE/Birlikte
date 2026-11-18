import '../../../core/theme/app_institutions.dart';

/// Puan özeti (Figma: `points-card` 201:173).
class PointsSummary {
  const PointsSummary({
    required this.total,
    required this.usable,
    required this.pending,
  });

  final int total;
  final int usable;
  final int pending;
}

/// Puan kazanma/kullanma koşulları — `GET /api/puan/kosullar`'dan.
///
/// Metin yönetimden değiştirilebilir; uygulamaya gömülmüyor, sayfası her
/// açıldığında yeniden çekiliyor (bkz. `pointsTermsAsyncProvider`'ın çağrı
/// yerlerindeki `ref.invalidate`). `versiyon` alanı yok sayılıyor — bu
/// yüzden gerek de kalmıyor, zaten her açılışta taze veri çekiliyor.
class PointsTerms {
  const PointsTerms({
    required this.baslik,
    required this.giris,
    required this.bolumler,
    this.guncellemeTarihi,
  });

  final String baslik;
  final String giris;
  final List<PointsTermsSection> bolumler;
  final DateTime? guncellemeTarihi;
}

/// Bir bölüm — başlık + düz metin madde listesi.
class PointsTermsSection {
  const PointsTermsSection({required this.baslik, required this.maddeler});

  final String baslik;
  final List<String> maddeler;
}

/// Kampanyanın eşleştiği ilgi alanı (Figma: `Chip / Category` —
/// `chips-row` 445:10135).
///
/// birlikte-api'den geliyor: sabit bir enum değil, kataloğun kendisi
/// `GET /api/ilgi-alanlari`'den (bkz. `InterestCategoryItem`) çekiliyor; bu
/// sınıf yalnızca bir kampanyanın HANGİ ilgi alanlarıyla eşleştiğini taşıyor.
/// Bir kampanya birden fazla ilgi alanıyla eşleşebilir — tek bir kategoriye
/// ait değil.
///
/// [CampaignCategoryOption] ile KARIŞTIRILMAMALI (backend'in kendi uyarısı):
/// bu sınıf "bu kampanya hangi ilgi alanlarıyla eşleşiyor" (`eslesen`), o
/// sınıf "sistemdeki tüm ilgi alanları + kullanıcı hangisini seçmiş"
/// (`secili`) sorusuna cevap verir — ayrı dizilerden, ayrı amaçlarla gelirler.
class InterestTag {
  const InterestTag({
    required this.id,
    required this.kod,
    required this.ad,
    this.eslesen = false,
  });

  final int id;
  final String kod;
  final String ad;

  /// Bu ilgi alanı, oturum sahibinin seçtiği ilgi alanlarıyla eşleşiyor mu —
  /// "sana özel" sıralamasında öne alınma ölçütü.
  final bool eslesen;
}

/// Kampanyalar sekmesinin kategori çipleri — `GET /api/kampanyalar`
/// yanıtının ÜST seviye `ilgiAlanlari` dizisinden (sistemdeki TÜM aktif ilgi
/// alanları, kampanyadan bağımsız).
///
/// [InterestTag] ile KARIŞTIRILMAMALI — bkz. oradaki not.
class CampaignCategoryOption {
  const CampaignCategoryOption({
    required this.id,
    required this.ad,
    required this.secili,
    this.ikon,
  });

  final int id;
  final String ad;
  final String? ikon;

  /// Kullanıcının kendi seçtiği ilgi alanlarından biri mi — o an aktif
  /// filtre bu olmasa bile çipte kalıcı bir işaret olarak gösterilir
  /// ("dolu çip gibi", backend'in kendi tabiriyle).
  final bool secili;
}

/// `GET /api/kampanyalar` yanıtının tamamı: kampanyalar zaten sunucuda
/// kullanıcının seçtiği ilgi alanlarına göre sıralı gelir (eşleşenler önde)
/// — istemci YENİDEN SIRALAMAZ, geldiği sırayla gösterir.
class CampaignsFeed {
  const CampaignsFeed({
    required this.campaigns,
    required this.categories,
    required this.selectedInterestCount,
  });

  final List<Campaign> campaigns;
  final List<CampaignCategoryOption> categories;

  /// `seciliIlgiAlaniSayisi` — 0 ise kullanıcı hiç ilgi alanı seçmemiş;
  /// ekran "ilgi alanlarını seç" yönlendirmesi göstermeli.
  final int selectedInterestCount;
}

/// Kampanyanın geçerli olduğu şube/kampüs (Figma: `branch-card`,
/// `campaign-branches` 398:9110).
class CampaignBranch {
  const CampaignBranch({
    required this.name,
    required this.distanceLabel,
    required this.address,
    required this.hours,
  });

  final String name;

  /// Örn. "4,2 km".
  final String distanceLabel;
  final String address;

  /// Örn. "Hafta içi 09:00 – 18:00".
  final String hours;
}

/// Kampanya kartı ve detayı (Figma: `Card / Campaign` 149:540,
/// `campaign-detail` 3:686).
///
/// Liste kartı yalnızca [brand], [title], [discountLabel], [daysLeft]
/// gerektirir; detay ekranındaki alanlar (`description`, `tags`, `steps`...)
/// isteğe bağlıdır — bir kampanyanın tam editoryal içeriği olmayabilir,
/// o durumda detay ekranı ilgili bölümü gizler.
class Campaign {
  const Campaign({
    required this.id,
    required this.brand,
    required this.title,
    required this.discountLabel,
    required this.daysLeft,
    this.ilgiAlanlari = const [],
    this.institution,
    this.pointsCost,
    this.imageUrl,
    this.brandType,
    this.description,
    this.validity,
    this.detayUrl,
    this.tags = const [],
    this.steps = const [],
    this.whoQualifies = const [],
    this.rules = const [],
    this.cancellationNote,
    this.branches = const [],
    this.kuponAlinabilir = true,
    this.puanBedeli = 0,
    this.kuponAldim = false,
    this.kuponum,
    this.favori = false,
  });

  /// birlikte-api `kampanyaGuid` — tek kimlik, hem adreslemede hem kupon/
  /// tıklama yazma isteklerinde kullanılıyor.
  final String id;
  final String brand;
  final String title;

  /// Örn. "%25", "150 TL", "Ücretsiz" — biçimi markaya göre değişir, düz
  /// metin olarak gösterilir.
  final String discountLabel;
  final int daysLeft;

  /// Kampanyanın eşleştiği ilgi alanları — tek bir sabit kategori değil,
  /// birden fazla olabilir (bkz. [InterestTag]).
  final List<InterestTag> ilgiAlanlari;

  /// birlikte-api kampanya başına kurum bilgisi vermiyor (kurum/kayıt tipi/
  /// cinsiyet kuralları zaten sunucuda uygulanıyor); bu alan hep null —
  /// kart ve detay bunu "tüm kurumlara özel" olarak gösteriyor.
  final Institution? institution;

  /// Kampanyanın puan karşılığı; 0/ücretsizse null — puan etiketi yalnızca
  /// gerçek bir bedel varsa gösterilir.
  final int? pointsCost;
  final String? imageUrl;

  /// Detay ekranı marka satırının alt metni. birlikte-api şu an bunu
  /// sağlamıyor; her zaman null.
  final String? brandType;
  final String? description;

  /// Örn. "1 Eylül 2026 — 31 Ocak 2027".
  final String? validity;

  /// Kampanyanın web sayfası — varsa detay sekmesinde bir bağlantı olarak
  /// gösterilir.
  final String? detayUrl;

  /// birlikte-api'de karşılığı yok; her zaman boş.
  final List<String> tags;

  /// "Nasıl kullanılır?" adımları. birlikte-api'de karşılığı yok; her zaman
  /// boş.
  final List<String> steps;

  /// "Kimler yararlanabilir?" listesi. birlikte-api'de karşılığı yok; her
  /// zaman boş.
  final List<String> whoQualifies;

  /// "Kampanya koşulları" listesi. birlikte-api'de karşılığı yok; her zaman
  /// boş.
  final List<String> rules;
  final String? cancellationNote;

  /// birlikte-api'de karşılığı yok; her zaman boş.
  final List<CampaignBranch> branches;

  /// Bu kampanyadan kupon alınabilir mi (kampanyada kupon yoksa, sabit kupon
  /// kodu girilmemişse ya da kota dolmuşsa false).
  final bool kuponAlinabilir;

  /// Kuponun kaç puana alındığı; ücretsizse 0.
  final int puanBedeli;

  /// Oturum sahibi bu kampanyadan kupon almış mı.
  final bool kuponAldim;

  /// Yalnızca detayda dolu gelir — [kuponAldim] true ise alınan kupon.
  final CampaignCoupon? kuponum;

  /// Oturum sahibi bu kampanyayı favorilemiş mi — `GET /api/kampanyalar`
  /// (liste), kampanya detayı ve `GET /api/me` içindeki kampanyalarda artık
  /// bulunan `favori` alanından.
  final bool favori;

  /// Detay ekranında "Koşullar" sekmesini göstermeye yeten içerik var mı.
  bool get hasTermsDetail =>
      whoQualifies.isNotEmpty || rules.isNotEmpty || cancellationNote != null;
}

/// Bir kampanyadan alınan kupon (Figma: `coupon-success_Main` 3:834 ve
/// kampanya detayının "kuponum" bilgisi).
///
/// Cüzdanım ekranındaki [UserCoupon]'dan farklı: burada marka/başlık/indirim
/// zaten kampanyanın kendisinden biliniyor, API yalnızca kod/durum/geçerlilik
/// döndürüyor.
class CampaignCoupon {
  const CampaignCoupon({required this.code, required this.status, this.expiresAt});

  final String code;

  /// `AKTIF` | `KULLANILDI` | `SURESI_DOLDU` (backend sözleşmesi).
  final String status;
  final DateTime? expiresAt;

  bool get isActive => status == 'AKTIF';
  bool get isUsed => status == 'KULLANILDI';
  bool get isExpired => status == 'SURESI_DOLDU';

  String get statusLabel => switch (status) {
    'KULLANILDI' => 'Kullanıldı',
    'SURESI_DOLDU' => 'Süresi doldu',
    _ => 'Aktif',
  };
}

/// Kan bağışı talebi (Figma: `request-row` 205:437).
///
/// `/api/kan-talepleri`'nden — talep bir kişiye değil hastaneye ait, bu
/// yüzden eski (Supabase döneminden kalma) `name` alanı yok; kart başlığı
/// artık [hospital].
class BloodRequest {
  const BloodRequest({
    required this.id,
    required this.bloodType,
    required this.hospital,
    this.location,
    this.description,
    this.urgent = false,
    this.pointsReward = 0,
    this.eligible,
    this.applied = false,
  });

  /// `kanTalebiGuid` — başvuru/iptal çağrılarında kullanılıyor.
  final String id;

  /// Örn. "A+".
  final String bloodType;
  final String hospital;

  /// Örn. "İstanbul".
  final String? location;
  final String? description;
  final bool urgent;

  /// Bağış tamamlanınca verilecek puan.
  final int pointsReward;

  /// Kullanıcının kan grubu bu talebe uyuyor mu — kan grubu hiç
  /// girilmediyse `null` ("kan grubunu ekle" yönlendirmesi gösterilir).
  final bool? eligible;

  /// Kullanıcı bu talebe zaten başvurmuş mu.
  final bool applied;
}

/// Aile üyesi (Figma: `member-row` 205:474).
class FamilyMember {
  const FamilyMember({required this.name, required this.relation});

  final String name;

  /// Örn. "Eş", "Çocuk".
  final String relation;

  /// Avatar baş harfleri — "Emre Yılmaz" → "EY".
  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((w) => w.substring(0, 1).toUpperCase())
      .join();
}

/// Kullanıcının oluşturduğu kupon (Cüzdanım ekranı).
class UserCoupon {
  const UserCoupon({
    required this.code,
    required this.brand,
    required this.title,
    required this.discountLabel,
    required this.status,
    this.expiresAt,
  });

  final String code;
  final String brand;
  final String title;
  final String discountLabel;

  /// `/api/me/kuponlar`'ın `durum` alanı: AKTIF | KULLANILDI | SURESI_DOLDU.
  /// İptal edilen kuponlar bu listede hiç gelmiyor (bkz. backend notu).
  final String status;
  final DateTime? expiresAt;

  bool get isActive => status == 'AKTIF';

  /// Rozet metni — kullanıcının kuponu ne durumda olduğunu bir bakışta
  /// anlaması için.
  String get statusLabel => switch (status) {
    'KULLANILDI' => 'Kullanıldı',
    'SURESI_DOLDU' => 'Süresi doldu',
    _ => 'Aktif',
  };
}
