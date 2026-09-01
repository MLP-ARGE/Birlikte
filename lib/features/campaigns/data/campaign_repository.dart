import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../../core/theme/app_institutions.dart';
import '../../home/domain/home_models.dart';

/// Kampanya okuma ve kupon üretimi.
///
/// Görünürlük (yayında mı, kullanıcının kurumuna açık mı) RLS tarafından
/// zorlanıyor; burada ayrıca filtrelemeye gerek yok.
class CampaignRepository {
  const CampaignRepository(this._client);

  final SupabaseClient _client;

  static const _columns = '''
    id, slug, title, discount_label, points_cost, institution_id, category_id,
    description, hero_image_path, ends_at, tags, steps, who_qualifies, rules,
    cancellation_note, starts_at,
    brands ( name, category_label ),
    campaign_branches ( name, address, opening_hours )
  ''';

  Future<List<Campaign>> fetchAll() async {
    final rows = await _client
        .from('campaigns')
        .select(_columns)
        .order('ends_at');
    return rows.map(_fromRow).toList();
  }

  Future<Campaign?> fetchBySlug(String slug) async {
    final rows = await _client
        .from('campaigns')
        .select(_columns)
        .eq('slug', slug)
        .limit(1);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  Future<Set<String>> fetchFavoriteIds() async {
    final rows = await _client
        .from('campaign_favorites')
        .select('campaigns ( slug )');
    return {
      for (final r in rows)
        if ((r['campaigns'] as Map?)?['slug'] case final String slug) slug,
    };
  }

  Future<void> toggleFavorite(String campaignId, {required bool add}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    if (add) {
      await _client.from('campaign_favorites').insert({
        'profile_id': userId,
        'campaign_id': campaignId,
      });
    } else {
      await _client
          .from('campaign_favorites')
          .delete()
          .eq('profile_id', userId)
          .eq('campaign_id', campaignId);
    }
  }

  /// Kupon üretir. Kod, kontenjan ve kişi başı limit sunucuda uygulanır;
  /// kural ihlalinde Postgres hata mesajı döner.
  Future<String> createCoupon(String campaignId) async {
    final result = await _client.rpc<Map<String, dynamic>>(
      'create_coupon',
      params: {'p_campaign_id': campaignId},
    );
    return result['code'] as String;
  }

  Campaign _fromRow(Map<String, dynamic> row) {
    final brand = (row['brands'] as Map?) ?? const {};
    final branches = (row['campaign_branches'] as List?) ?? const [];
    final endsAt = DateTime.parse(row['ends_at'] as String);

    return Campaign(
      // Uygulama içinde kampanyayı `slug` ile adresliyoruz (okunur URL);
      // yazma işlemleri için gereken uuid ayrı tutuluyor.
      id: row['slug'] as String,
      remoteId: row['id'] as String,
      brand: (brand['name'] as String?) ?? '',
      brandType: brand['category_label'] as String?,
      title: row['title'] as String,
      discountLabel: row['discount_label'] as String,
      daysLeft: endsAt.difference(DateTime.now()).inDays,
      category: _categoryFromId(row['category_id'] as int),
      institution: switch (row['institution_id'] as int?) {
        1 => Institution.medicalPark,
        2 => Institution.livHospital,
        3 => Institution.livKoleji,
        4 => Institution.istinyeUniversitesi,
        _ => null,
      },
      pointsCost: row['points_cost'] as int?,
      imageUrl: row['hero_image_path'] as String?,
      description: row['description'] as String?,
      validity: _formatValidity(row),
      tags: _stringList(row['tags']),
      steps: _stringList(row['steps']),
      whoQualifies: _stringList(row['who_qualifies']),
      rules: _stringList(row['rules']),
      cancellationNote: row['cancellation_note'] as String?,
      branches: [
        for (final b in branches)
          CampaignBranch(
            name: (b['name'] as String?) ?? '',
            // Mesafe konum servisiyle hesaplanacak; şimdilik boş.
            distanceLabel: '',
            address: (b['address'] as String?) ?? '',
            hours: (b['opening_hours'] as String?) ?? '',
          ),
      ],
    );
  }

  static List<String> _stringList(Object? value) =>
      (value as List?)?.cast<String>() ?? const [];

  static String? _formatValidity(Map<String, dynamic> row) {
    final starts = DateTime.tryParse(row['starts_at'] as String? ?? '');
    final ends = DateTime.tryParse(row['ends_at'] as String? ?? '');
    if (starts == null || ends == null) return null;
    return '${starts.day}.${starts.month}.${starts.year} — '
        '${ends.day}.${ends.month}.${ends.year}';
  }

  /// `public.campaign_categories.id` → uygulamadaki enum. Kodlar migration
  /// 20260901000200'de enum ile birebir eşleşecek şekilde tanımlandı.
  static CampaignCategory _categoryFromId(int id) => switch (id) {
    1 => CampaignCategory.foodDrink,
    2 => CampaignCategory.shopping,
    3 => CampaignCategory.health,
    4 => CampaignCategory.education,
    5 => CampaignCategory.automotive,
    6 => CampaignCategory.travel,
    7 => CampaignCategory.fuel,
    8 => CampaignCategory.pets,
    _ => CampaignCategory.shopping,
  };
}

final campaignRepositoryProvider = Provider<CampaignRepository>(
  (ref) => CampaignRepository(ref.watch(supabaseProvider)),
);
