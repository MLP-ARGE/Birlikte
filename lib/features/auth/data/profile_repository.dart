import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../../core/theme/app_institutions.dart';
import '../domain/verified_profile.dart';

/// Profil okuma/yazma.
///
/// RLS sayesinde sorgularda `where profile_id = ...` yazmaya gerek yok;
/// veritabanı zaten yalnızca oturum sahibinin satırını döndürüyor.
class ProfileRepository {
  const ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<VerifiedProfile?> fetch() async {
    final rows = await _client
        .from('profiles')
        .select('full_name, employee_no, institution_id, department, '
            'region, facility, avatar_path, language, theme, '
            'position, email, manager_name, person_type, hired_at')
        .limit(1);

    if (rows.isEmpty) return null;
    final row = rows.first;
    return _fromRow(row, await _avatarUrl(row['avatar_path'] as String?));
  }

  /// Avatar bucket'ı özel (çalışan fotoğrafı kişisel veri), o yüzden
  /// doğrudan URL yok — kısa ömürlü imzalı bağlantı üretiyoruz. RLS
  /// yalnızca kullanıcının kendi dosyasına izin veriyor.
  ///
  /// Fotoğraf çekilemezse profil yine yüklenir; avatar baş harflere düşer.
  Future<String?> _avatarUrl(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      return await _client.storage
          .from('avatars')
          .createSignedUrl(path, _avatarUrlTtl.inSeconds);
    } catch (_) {
      return null;
    }
  }

  /// İmzalı bağlantı ömrü. Oturum boyunca yeniden üretmeye gerek kalmasın
  /// diye uzun tutuluyor; fotoğraf zaten değişmiyor.
  static const _avatarUrlTtl = Duration(hours: 6);

  Future<void> updateAppearance({String? language, String? theme}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('profiles').update({
      'language': ?language,
      'theme': ?theme,
    }).eq('id', userId);
  }

  static VerifiedProfile _fromRow(Map<String, dynamic> row, String? avatarUrl) {
    return VerifiedProfile(
      fullName: row['full_name'] as String,
      employeeNo: row['employee_no'] as String,
      institution: _institutionFromId(row['institution_id'] as int),
      department: (row['department'] as String?) ?? '',
      region: (row['region'] as String?) ?? '',
      facility: (row['facility'] as String?) ?? '',
      // Bordro eşleşme tarihi profil tablosunda tutulmuyor; kurum onay
      // ekranı bunu ayrıca çekiyor.
      matchedAt: DateTime.now(),
      photoUrl: avatarUrl,
      position: row['position'] as String?,
      email: row['email'] as String?,
      managerName: row['manager_name'] as String?,
      personType: row['person_type'] as String?,
      hiredAt: DateTime.tryParse((row['hired_at'] as String?) ?? ''),
      language: (row['language'] as String?) ?? 'tr',
      theme: (row['theme'] as String?) ?? 'system',
    );
  }

  /// `public.institutions.id` → uygulamadaki enum.
  ///
  /// Veritabanındaki id'ler migration'da sabit (1..4) ve enum sırası ile
  /// eşleşiyor; yine de açıkça eşliyoruz ki sıralama değişirse sessizce
  /// yanlış kurum gösterilmesin.
  static Institution _institutionFromId(int id) => switch (id) {
    1 => Institution.medicalPark,
    2 => Institution.livHospital,
    3 => Institution.livKoleji,
    4 => Institution.istinyeUniversitesi,
    _ => Institution.medicalPark,
  };
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(supabaseProvider)),
);

/// Oturum sahibinin profili. Giriş/çıkışta kendini yeniler.
final profileProvider = FutureProvider<VerifiedProfile?>((ref) async {
  ref.watch(authStateProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(profileRepositoryProvider).fetch();
});
