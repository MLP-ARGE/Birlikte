import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/birlikte_api/birlikte_api_client.dart';
import '../../home/domain/home_models.dart';

/// Kampanya okuma ve kupon üretimi — birlikte-api üzerinden.
///
/// Görünürlük (yayında mı, kullanıcının kurumuna/kayıt tipine/cinsiyetine
/// açık mı) sunucuda uygulanıyor; istemci ayrıca filtrelemiyor.
class CampaignRepository {
  const CampaignRepository(this._api);

  final BirlikteApiClient _api;

  /// Sunucu sayfa başına en fazla 100 kayıt veriyor; tek seferde tamamını
  /// göstermek için gerektiği kadar sayfa art arda çekiliyor. 20 sayfa
  /// (2000 kampanya) güvenlik sınırı — kataloğun bunu aşması beklenmiyor.
  static const _pageSize = 100;
  static const _maxPages = 20;

  /// [ilgiAlaniId] tek bir kategoriye, [sadeceIlgili] kullanıcının seçtiği
  /// TÜM ilgi alanlarına göre sunucu taraflı filtreler — istemci ayrıca
  /// filtrelemiyor. Üst seviye `ilgiAlanlari` kataloğu ve
  /// `seciliIlgiAlaniSayisi` yalnızca ilk sayfadan okunuyor, sayfalar
  /// arasında değişmiyor.
  Future<CampaignsFeed> fetchAll({
    int? ilgiAlaniId,
    bool sadeceIlgili = false,
  }) async {
    final campaigns = <Campaign>[];
    var categories = const <CampaignCategoryOption>[];
    var selectedInterestCount = 0;
    var sayfa = 1;
    while (sayfa <= _maxPages) {
      final veri = await _api.kampanyalar(
        sayfa: sayfa,
        sayfaBoyutu: _pageSize,
        ilgiAlaniId: ilgiAlaniId,
        sadeceIlgili: sadeceIlgili ? true : null,
      );
      if (sayfa == 1) {
        categories = (veri['ilgiAlanlari'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map(_categoryFromRow)
            .toList();
        selectedInterestCount =
            (veri['seciliIlgiAlaniSayisi'] as num?)?.toInt() ?? 0;
      }
      final rows = (veri['kampanyalar'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      campaigns.addAll(rows.map(_fromListRow));
      final toplam = (veri['toplamKayit'] as num?)?.toInt() ?? rows.length;
      if (campaigns.length >= toplam || rows.isEmpty) break;
      sayfa++;
    }
    return CampaignsFeed(
      campaigns: campaigns,
      categories: categories,
      selectedInterestCount: selectedInterestCount,
    );
  }

  static CampaignCategoryOption _categoryFromRow(Map<String, dynamic> row) =>
      CampaignCategoryOption(
        id: (row['ilgiAlaniId'] as num).toInt(),
        ad: (row['ad'] as String?) ?? '',
        ikon: row['ikon'] as String?,
        secili: row['secili'] as bool? ?? false,
      );

  Future<Campaign> fetchDetail(String kampanyaGuid) async {
    final veri = await _api.kampanyaDetay(kampanyaGuid);
    return _fromDetailRow(veri);
  }

  /// Kampanya görüntülendiğinde bir kez çağrılır (analitik — "yeni" rozetini
  /// ve kişiye özel sıralamayı besliyor). Sessizce yutuluyor: tıklama
  /// kaydının başarısız olması kullanıcıya kampanyayı göstermeyi
  /// engellememeli.
  Future<void> recordClick(String kampanyaGuid) async {
    try {
      await _api.kampanyaTiklama(kampanyaGuid);
    } catch (_) {
      // bkz. yukarıdaki not.
    }
  }

  /// Kupon kodu üretir. Aynı kampanyadan tekrar istenirse sunucu aynı
  /// kuponu döner (`KUPON_MEVCUT`, `alreadyExisted: true`) — yeni kupon
  /// oluşmaz, puan tekrar düşmez; çağıran taraf buna göre "kuponun hazır"
  /// yerine "zaten kuponun var" göstermeli (backend'in mobil kuralı). Hata
  /// kodları: `KUPON_YOK` (400), `KAMPANYA_BULUNAMADI` (404), `KOTA_DOLDU`
  /// (409), `YETERSIZ_PUAN` (409).
  Future<({bool alreadyExisted, CampaignCoupon coupon})> createCoupon(
    String kampanyaGuid,
  ) async {
    final (code, veri) = await _api.kuponAl(kampanyaGuid);
    return (alreadyExisted: code == 'KUPON_MEVCUT', coupon: _couponFromRow(veri));
  }

  /// Favoriye ekler/çıkarır. Zaten o durumdaysa da sunucu aynı başarılı
  /// yanıtı döner — çağıran taraf önce kontrol etmek zorunda değil.
  Future<void> setFavorite(String kampanyaGuid, bool favori) => favori
      ? _api.favoriKampanyaEkle(kampanyaGuid)
      : _api.favoriKampanyaCikar(kampanyaGuid);

  static Campaign _fromListRow(Map<String, dynamic> row) =>
      _campaignFrom(row, description: _str(row['kisaAciklama']));

  static Campaign _fromDetailRow(Map<String, dynamic> row) => _campaignFrom(
    row,
    description: _str(row['icerik']) ?? _str(row['kisaAciklama']),
    detayUrl: _str(row['detayUrl']),
  );

  static Campaign _campaignFrom(
    Map<String, dynamic> row, {
    String? description,
    String? detayUrl,
  }) {
    final baslangic = DateTime.tryParse(_str(row['baslangicTarihi']) ?? '');
    final bitis = DateTime.tryParse(_str(row['bitisTarihi']) ?? '');
    final puanBedeli = (row['puanBedeli'] as num?)?.toInt() ?? 0;

    return Campaign(
      id: row['kampanyaGuid'] as String,
      brand: _str(row['firma']) ?? '',
      title: (row['baslik'] as String?) ?? '',
      discountLabel: (row['indirimMetni'] as String?) ?? '',
      daysLeft: bitis == null ? 0 : bitis.difference(DateTime.now()).inDays,
      imageUrl: _str(row['gorselUrl']),
      description: description,
      validity: _formatValidity(baslangic, bitis),
      detayUrl: detayUrl,
      ilgiAlanlari: (row['ilgiAlanlari'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(
            (t) => InterestTag(
              id: (t['ilgiAlaniId'] as num).toInt(),
              kod: (t['kod'] as String?) ?? '',
              ad: (t['ad'] as String?) ?? '',
              eslesen: t['eslesen'] as bool? ?? false,
            ),
          )
          .toList(),
      pointsCost: puanBedeli > 0 ? puanBedeli : null,
      // kuponAlinabilir/kuponAldim alanları henüz yalnızca test ortamında
      // (NestJS); üretim (.NET) tarafı eklenene kadar alan yoksa sabit
      // kuponlu kampanyalarda kuponKodu'na bakarak makul bir varsayılan
      // üretiyoruz — alan geldiğinde bu satır onu doğrudan kullanacak.
      kuponAlinabilir: row.containsKey('kuponAlinabilir')
          ? row['kuponAlinabilir'] as bool
          : true,
      kuponAldim: row.containsKey('kuponAldim')
          ? row['kuponAldim'] as bool
          : false,
      kuponum: row['kuponum'] is Map<String, dynamic>
          ? _couponFromRow(row['kuponum'] as Map<String, dynamic>)
          : null,
      favori: row['favori'] as bool? ?? false,
    );
  }

  static CampaignCoupon _couponFromRow(Map<String, dynamic> row) =>
      CampaignCoupon(
        code: (row['kod'] as String?) ?? '',
        status: (row['durum'] as String?) ?? 'AKTIF',
        expiresAt: DateTime.tryParse(_str(row['gecerlilikSonu']) ?? ''),
      );

  static String? _str(Object? value) => value as String?;

  static String? _formatValidity(DateTime? starts, DateTime? ends) {
    if (starts == null || ends == null) return null;
    return '${starts.day}.${starts.month}.${starts.year} — '
        '${ends.day}.${ends.month}.${ends.year}';
  }
}

final campaignRepositoryProvider = Provider<CampaignRepository>(
  (ref) => CampaignRepository(ref.watch(birlikteApiClientProvider)),
);
