import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/birlikte_api/birlikte_api_client.dart';
import '../../../core/birlikte_api/birlikte_session_provider.dart';
import '../../../core/theme/app_institutions.dart';
import '../domain/verified_profile.dart';

/// Profil okuma — birlikte-api `GET /api/me` üzerinden.
///
/// Yanıt tek bir nesne değil, kişinin tüm aktif kayıtlarının (çalışan/
/// öğrenci/yakın, `kayitTipi` ile ayrılır) bir DİZİSİ; uygulama şimdilik tek
/// bir profil gösterdiğinden çalışan kaydı varsa o, yoksa ilk kayıt alınıyor.
class ProfileRepository {
  const ProfileRepository(this._api);

  final BirlikteApiClient _api;

  Future<VerifiedProfile?> fetch() async {
    // Kampanyalar ayrıca `campaignsAsyncProvider` üzerinden çekiliyor; burada
    // ihtiyaç duyulmuyor, istek gövdesini küçük tutmak için 0 isteniyor.
    final rows = (await _api.me(kampanyaSayisi: 0)).cast<Map<String, dynamic>>();
    if (rows.isEmpty) return null;
    final row = rows.firstWhere(
      (r) => r['kayitTipi'] == 'CALISAN',
      orElse: () => rows.first,
    );
    return _fromRow(row);
  }

  /// Eksik bilgilerden kullanıcının kendisi yalnızca cinsiyeti
  /// tamamlayabiliyor (ad/soyad kurum kaydından düzeltilir).
  Future<void> completeGender(String cinsiyet) =>
      _api.completeMissingInfo(cinsiyet: cinsiyet);

  static VerifiedProfile _fromRow(Map<String, dynamic> row) {
    final ilgiAlanlari = row['ilgiAlanlari'] as List<dynamic>? ?? const [];
    return VerifiedProfile(
      fullName: '${(row['ad'] as String?) ?? ''} ${(row['soyad'] as String?) ?? ''}'
          .trim(),
      institution: _institutionFromKurumKodu(row['kurumKodu'] as String?),
      // birlikte-api bölge kavramı vermiyor; departman/şube ile yetiniyoruz.
      region: '',
      department: (row['departman'] as String?) ?? '',
      facility: (row['subeAdi'] as String?) ?? '',
      // birlikte-api sicil numarası vermiyor.
      employeeNo: null,
      // Eşleşme tarihi ayrıca tutulmuyor; profil her çekildiğinde "şimdi"
      // olarak gösteriliyor (PDKS döneminden kalan aynı yaklaşım).
      matchedAt: DateTime.now(),
      position: row['unvan'] as String?,
      email: row['eposta'] as String?,
      personType: row['kayitTipi'] as String?,
      interestCount: ilgiAlanlari.length,
      missingInfo: (row['eksikBilgiler'] as List<dynamic>? ?? const [])
          .cast<String>(),
    );
  }

  /// Yalnızca "MLP" (Medical Park/MLP Care) doğrulandı; Liv Hospital, Liv
  /// Koleji ve İstinye Üniversitesi'nin kurumKodu karşılığı henüz
  /// paylaşılmadı. Bilinmeyen bir kod rozetin rengini/logosunu etkiler ama
  /// uygulamayı kilitlemez — Medical Park'a düşer.
  static Institution _institutionFromKurumKodu(String? kod) => switch (kod) {
    'MLP' => Institution.medicalPark,
    _ => Institution.medicalPark,
  };
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(birlikteApiClientProvider)),
);

/// Oturum sahibinin profili. Giriş/çıkışta kendini yeniler.
final profileProvider = FutureProvider<VerifiedProfile?>((ref) async {
  final loggedIn = ref.watch(birlikteSessionProvider);
  if (!loggedIn) return null;
  return ref.watch(profileRepositoryProvider).fetch();
});
