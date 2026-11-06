import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Favori kampanyaların cihazda saklanması.
///
/// birlikte-api'de favori/yer imi ucu yok (bkz. Postman koleksiyonunun 6
/// bölümü — kupon/puan/kan bağışı var, favori yok); bu yüzden favoriler
/// sunucuya değil yalnızca bu cihaza yazılıyor. Kullanıcı telefon
/// değiştirirse favorileri sıfırdan kurar — backend bir uç eklerse bu sınıf
/// sunucu çağrısına çevrilebilir, çağıran taraf (`FavoriteCampaignIds`)
/// değişmeden kalır.
class FavoritesRepository {
  FavoritesRepository(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _key = 'birlikte_favorite_campaign_ids';

  Future<Set<String>> fetchIds() async =>
      (await _prefs.getStringList(_key))?.toSet() ?? {};

  Future<void> save(Set<String> ids) => _prefs.setStringList(_key, ids.toList());
}

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepository(SharedPreferencesAsync()),
);
