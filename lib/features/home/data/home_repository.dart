import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../domain/home_models.dart';

/// Ana sayfadaki puan, kan talebi ve aile bölümlerinin veri kaynağı.
///
/// Bu üç bölüm daha önce Figma'daki örnek içeriği sabit olarak gösteriyordu.
/// Kullanıcıya gerçek sanılan uydurma veri göstermek yanlış; artık hepsi
/// Supabase'den geliyor ve kayıt yoksa bölümler boş durumlarını gösteriyor.
///
/// Erişim denetimi RLS'te: kullanıcı yalnızca kendi puanını ve kendi
/// yakınlarını görüyor, kan taleplerinde ise açık olanların tamamı görünüyor
/// (özelliğin amacı bu).
class HomeRepository {
  const HomeRepository(this._client);

  final SupabaseClient _client;

  /// Puan özeti. Hiç hareket yoksa view satır döndürmüyor; sıfır dönüyoruz.
  Future<PointsSummary> fetchPoints() async {
    final rows = await _client
        .from('point_balances')
        .select('total, usable, pending')
        .limit(1);

    if (rows.isEmpty) {
      return const PointsSummary(total: 0, usable: 0, pending: 0);
    }
    final r = rows.first;
    return PointsSummary(
      total: (r['total'] as num?)?.toInt() ?? 0,
      usable: (r['usable'] as num?)?.toInt() ?? 0,
      pending: (r['pending'] as num?)?.toInt() ?? 0,
    );
  }

  /// Açık kan talepleri — acil olanlar önce, sonra en yeni.
  ///
  /// Hasta adı yerine baş harfler tutuluyor (`patient_initials`): kan talebi
  /// sağlık verisidir, kimliği açık etmemek gerekiyor.
  Future<List<BloodRequest>> fetchBloodRequests({int limit = 5}) async {
    final rows = await _client
        .from('blood_requests')
        .select('patient_initials, blood_type, urgency, '
            'hospitals ( name )')
        .eq('status', 'open')
        .order('urgency', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);

    return [
      for (final r in rows)
        BloodRequest(
          name: (r['patient_initials'] as String?) ?? '',
          bloodType: (r['blood_type'] as String?) ?? '',
          hospital: ((r['hospitals'] as Map?)?['name'] as String?) ?? '',
          urgent: r['urgency'] == 'urgent',
        ),
    ];
  }

  /// Kullanıcının kuponları — en yenisi önce.
  ///
  /// RLS kullanıcıyı yalnızca kendi kuponlarına bırakıyor, sorguda ayrıca
  /// süzmeye gerek yok.
  Future<List<UserCoupon>> fetchCoupons() async {
    final rows = await _client
        .from('coupons')
        .select('code, status, expires_at, used_at, '
            'campaigns ( title, discount_label, brands ( name ) )')
        .order('issued_at', ascending: false);

    return [
      for (final r in rows)
        () {
          final c = (r['campaigns'] as Map?) ?? const {};
          final b = (c['brands'] as Map?) ?? const {};
          return UserCoupon(
            code: (r['code'] as String?) ?? '',
            brand: (b['name'] as String?) ?? '',
            title: (c['title'] as String?) ?? '',
            discountLabel: (c['discount_label'] as String?) ?? '',
            status: (r['status'] as String?) ?? 'active',
            expiresAt: DateTime.tryParse((r['expires_at'] as String?) ?? ''),
          );
        }(),
    ];
  }

  /// Kullanıcının eklediği yakınlar. Yalnızca aktif olanlar gösteriliyor;
  /// davet edilmiş ama onaylanmamış kayıtlar listeyi şişirmesin.
  Future<List<FamilyMember>> fetchFamilyMembers() async {
    final rows = await _client
        .from('family_members')
        .select('full_name, relation')
        .eq('status', 'active')
        .order('created_at');

    return [
      for (final r in rows)
        FamilyMember(
          name: (r['full_name'] as String?) ?? '',
          relation: (r['relation'] as String?) ?? '',
        ),
    ];
  }
}

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepository(ref.watch(supabaseProvider)),
);
