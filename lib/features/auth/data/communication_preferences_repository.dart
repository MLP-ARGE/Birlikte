import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/birlikte_api/birlikte_api_client.dart';

/// Ticari ileti kanalı — yalnızca "kampanya" kategorisi var şimdilik, bu
/// yüzden kategori hiç taşınmıyor (backend: "kategori göndermeye gerek
/// yok").
enum CommunicationChannel { push, sms, eposta }

extension on CommunicationChannel {
  String get kod => switch (this) {
    CommunicationChannel.push => 'PUSH',
    CommunicationChannel.sms => 'SMS',
    CommunicationChannel.eposta => 'EPOSTA',
  };
}

CommunicationChannel? _parseChannel(String? value) => switch (value) {
  'PUSH' => CommunicationChannel.push,
  'SMS' => CommunicationChannel.sms,
  'EPOSTA' => CommunicationChannel.eposta,
  _ => null,
};

/// Tek bir kanalın durumu.
///
/// Kampanya push'u artık VARSAYILAN AÇIK (opt-out) — [onay] kullanıcının
/// verdiği KARARI taşır (`null` = hiç karar vermedi), [etkin] ise ŞU AN
/// geçerli olan durumu taşır (karar yoksa `true`). Ekranlar anahtarları
/// her zaman [etkin]'e göre çizmeli, [onay]'a göre DEĞİL.
class CommunicationPreference {
  const CommunicationPreference({
    required this.kanal,
    required this.onay,
    required this.etkin,
  });

  final CommunicationChannel kanal;
  final bool? onay;
  final bool etkin;
}

class CommunicationPreferences {
  const CommunicationPreferences({
    required this.sorulmali,
    required this.tercihler,
  });

  /// `true` ise hiçbir kanala karar verilmemiş — izin ekranı gösterilmeli
  /// (varsayılan açık olsa bile kullanıcı bilinçli karar vermeli).
  final bool sorulmali;
  final List<CommunicationPreference> tercihler;

  /// Şu an kampanya bildirimi gidiyor mu — karar yoksa `true` (opt-out).
  bool isEnabled(CommunicationChannel kanal) {
    for (final t in tercihler) {
      if (t.kanal == kanal) return t.etkin;
    }
    return true;
  }

  factory CommunicationPreferences.fromJson(Map<String, dynamic> json) {
    final tercihler = (json['tercihler'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(
          (m) => (
            _parseChannel(m['kanal'] as String?),
            m['onay'] as bool?,
            m['etkin'] as bool?,
          ),
        )
        .where((e) => e.$1 != null)
        .map(
          (e) => CommunicationPreference(
            kanal: e.$1!,
            onay: e.$2,
            // Alan beklenmedik şekilde gelmezse opt-out varsayımıyla açık
            // kabul ediliyor — kapalı göstermek false-positive bir
            // engelleme olurdu.
            etkin: e.$3 ?? true,
          ),
        )
        .toList();
    return CommunicationPreferences(
      sorulmali: json['sorulmali'] as bool? ?? false,
      tercihler: tercihler,
    );
  }
}

/// Kullanıcıya gösterilen izin metninin versiyonu — ispat için backend'e
/// gönderiliyor.
///
/// GEÇİCİ: ekrandaki metin hukuk birimi tarafından henüz hazırlanmadı
/// (backend'in kendi notu); gerçek metin ve versiyon numarası gelince hem
/// `CommunicationConsentPage`'deki yer tutucu metin hem bu sabit
/// güncellenmeli.
const communicationConsentTextVersion = '1.0';

class CommunicationPreferencesRepository {
  const CommunicationPreferencesRepository(this._api);

  final BirlikteApiClient _api;

  Future<CommunicationPreferences> fetch() async {
    final json = await _api.iletisimTercihleri();
    return CommunicationPreferences.fromJson(json);
  }

  Future<CommunicationPreferences> save(
    Map<CommunicationChannel, bool> degisenler,
  ) async {
    final json = await _api.iletisimTercihleriniKaydet(
      tercihler: [
        for (final entry in degisenler.entries)
          {'kanal': entry.key.kod, 'onay': entry.value},
      ],
      metinVersiyon: communicationConsentTextVersion,
    );
    return CommunicationPreferences.fromJson(json);
  }
}

final communicationPreferencesRepositoryProvider =
    Provider<CommunicationPreferencesRepository>(
      (ref) =>
          CommunicationPreferencesRepository(ref.watch(birlikteApiClientProvider)),
    );

final communicationPreferencesProvider =
    FutureProvider<CommunicationPreferences>((ref) async {
      return ref.watch(communicationPreferencesRepositoryProvider).fetch();
    });
