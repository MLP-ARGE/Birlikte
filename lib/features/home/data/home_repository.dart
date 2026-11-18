import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/birlikte_api/birlikte_api_client.dart';
import '../domain/home_models.dart';

/// Ana sayfadaki puan, kan talebi, kupon ve aile bölümlerinin veri kaynağı.
///
/// Tüm dört uç da (`/api/me/yakinlar`, `/api/me/puan`, `/api/me/kuponlar`,
/// `/api/kan-talepleri`) artık birlikte-api'den geliyor; alan adları backend
/// ekibiyle doğrulandı.
class HomeRepository {
  const HomeRepository(this._api);

  final BirlikteApiClient _api;

  /// Backend yalnızca `bakiye` (harcanabilir toplam) veriyor — "bekleyen"
  /// kazanım kavramı yok, bu yüzden `usable` ile `total` aynı ve `pending`
  /// hep 0. Uydurma bir ayrım göstermektense gerçek veriyle tutarlı kalıyor.
  Future<PointsSummary> fetchPoints() async {
    final veri = await _api.puanBakiyem();
    final bakiye = (veri['bakiye'] as num?)?.toInt() ?? 0;
    return PointsSummary(total: bakiye, usable: bakiye, pending: 0);
  }

  Future<List<BloodRequest>> fetchBloodRequests({
    int sayfa = 1,
    int sayfaBoyutu = 20,
  }) async {
    final veri = await _api.kanTalepleri(sayfa: sayfa, sayfaBoyutu: sayfaBoyutu);
    final rows = (veri['talepler'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return rows.map(_bloodRequestFromRow).toList();
  }

  /// Metin yönetimden değiştirilebilir; her çağrı sunucudan taze veri
  /// getirir, uygulama tarafında gömülü/önbellekli bir kopyası yok.
  Future<PointsTerms> fetchPointsTerms() async {
    final veri = await _api.puanKosullari();
    final bolumler = (veri['bolumler'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return PointsTerms(
      baslik: (veri['baslik'] as String?) ?? '',
      giris: (veri['giris'] as String?) ?? '',
      bolumler: bolumler
          .map(
            (b) => PointsTermsSection(
              baslik: (b['baslik'] as String?) ?? '',
              maddeler: (b['maddeler'] as List<dynamic>? ?? [])
                  .cast<String>(),
            ),
          )
          .toList(),
      guncellemeTarihi: DateTime.tryParse(
        (veri['guncellemeTarihi'] as String?) ?? '',
      ),
    );
  }

  Future<void> applyToBloodRequest(String kanTalebiGuid) =>
      _api.kanBasvurusuYap(kanTalebiGuid);

  Future<void> cancelBloodRequestApplication(String kanTalebiGuid) =>
      _api.kanBasvurusunuGeriCek(kanTalebiGuid);

  /// Silmek için `null` gönder. Okuma ayrı bir uca çıkmıyor — `/api/me`
  /// zaten `kanGrubu` alanını veriyor (bkz. `VerifiedProfile.bloodType`).
  Future<void> saveBloodType(String? kanGrubu) =>
      _api.kanGrubuKaydet(kanGrubu: kanGrubu);

  static BloodRequest _bloodRequestFromRow(Map<String, dynamic> row) =>
      BloodRequest(
        id: row['kanTalebiGuid'] as String,
        bloodType: (row['kanGrubu'] as String?) ?? '',
        hospital: (row['hastane'] as String?) ?? '',
        location: row['il'] as String?,
        description: row['aciklama'] as String?,
        urgent: row['aciliyet'] == 'ACIL',
        pointsReward: (row['puanOdulu'] as num?)?.toInt() ?? 0,
        eligible: row['uygun'] as bool?,
        applied: row['basvurdum'] as bool? ?? false,
      );

  Future<List<UserCoupon>> fetchCoupons() async {
    final rows = (await _api.kuponlarim()).cast<Map<String, dynamic>>();
    return rows.map(_couponFromRow).toList();
  }

  static UserCoupon _couponFromRow(Map<String, dynamic> row) => UserCoupon(
    code: (row['kod'] as String?) ?? '',
    brand: (row['firma'] as String?) ?? '',
    title: (row['baslik'] as String?) ?? '',
    discountLabel: (row['indirimMetni'] as String?) ?? '',
    status: (row['durum'] as String?) ?? 'AKTIF',
    expiresAt: DateTime.tryParse((row['gecerlilikSonu'] as String?) ?? ''),
  );

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
