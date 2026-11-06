import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../birlikte_api/birlikte_api_client.dart';

enum GuncellemeDurumu { guncel, onerilen, zorunlu }

GuncellemeDurumu _parseDurum(String? value) => switch (value) {
  'ZORUNLU' => GuncellemeDurumu.zorunlu,
  'ONERILEN' => GuncellemeDurumu.onerilen,
  _ => GuncellemeDurumu.guncel,
};

class GuncellemeBilgisi {
  const GuncellemeBilgisi({required this.durum, this.magazaUrl, this.mesaj});

  final GuncellemeDurumu durum;
  final String? magazaUrl;
  final String? mesaj;

  factory GuncellemeBilgisi.fromJson(Map<String, dynamic> json) {
    return GuncellemeBilgisi(
      durum: _parseDurum(json['durum'] as String?),
      magazaUrl: json['magazaUrl'] as String?,
      mesaj: json['mesaj'] as String?,
    );
  }
}

class AppDuyurusu {
  const AppDuyurusu({required this.baslik, required this.metin});

  final String baslik;
  final String metin;

  factory AppDuyurusu.fromJson(Map<String, dynamic> json) {
    return AppDuyurusu(
      baslik: json['baslik'] as String? ?? '',
      metin: json['metin'] as String? ?? '',
    );
  }
}

class RemoteAppConfig {
  const RemoteAppConfig({
    required this.bakimModu,
    this.bakimMesaji,
    required this.guncelleme,
    this.duyuru,
  });

  final bool bakimModu;
  final String? bakimMesaji;
  final GuncellemeBilgisi guncelleme;
  final AppDuyurusu? duyuru;

  factory RemoteAppConfig.fromJson(Map<String, dynamic> json) {
    return RemoteAppConfig(
      bakimModu: json['bakimModu'] as bool? ?? false,
      bakimMesaji: json['bakimMesaji'] as String?,
      guncelleme: GuncellemeBilgisi.fromJson(
        json['guncelleme'] as Map<String, dynamic>? ?? const {},
      ),
      duyuru: switch (json['duyuru']) {
        final Map<String, dynamic> d => AppDuyurusu.fromJson(d),
        _ => null,
      },
    );
  }
}

/// Uygulama açılış kontrolü (`GET /api/app/config`) — token gerekmez, mobil
/// giriş ekranından ÖNCE çağrılır.
///
/// Spec'in kendi kuralı: uç hata verirse (ağ, 5xx) uygulama kilitlenmemeli,
/// normal akışa devam etmeli. Bu yüzden her hata `null` olarak yutuluyor —
/// çağıran taraf (`SplashPage`) `null`'ı "bakım/güncelleme bilgisi yok, devam
/// et" olarak okuyor.
class AppConfigRepository {
  AppConfigRepository(this._api);

  final BirlikteApiClient _api;

  Future<RemoteAppConfig?> fetch() async {
    try {
      final version = (await PackageInfo.fromPlatform()).version;
      final json = await _api.appConfig(
        platform: Platform.isIOS ? 'IOS' : 'ANDROID',
        surum: version,
      );
      return RemoteAppConfig.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}

final appConfigRepositoryProvider = Provider<AppConfigRepository>(
  (ref) => AppConfigRepository(ref.watch(birlikteApiClientProvider)),
);

/// Splash'ta bir kez doldurulur; Home ilk render'ında ÖNERİLEN güncelleme/
/// duyuru bildirimini göstermek için okunup tüketilir (bkz.
/// `app_update_prompt.dart`). ZORUNLU/bakım splash'ın kendisi, kendi
/// ekranına yönlendirerek ele alıyor — bu provider sadece engellemeyen
/// (bilgilendirici) durumlar için.
class PendingAppNotice extends Notifier<RemoteAppConfig?> {
  @override
  RemoteAppConfig? build() => null;

  void set(RemoteAppConfig? value) => state = value;

  RemoteAppConfig? consume() {
    final value = state;
    state = null;
    return value;
  }
}

final pendingAppNoticeProvider =
    NotifierProvider<PendingAppNotice, RemoteAppConfig?>(PendingAppNotice.new);
