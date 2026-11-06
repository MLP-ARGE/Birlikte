import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/birlikte_api/birlikte_api_client.dart';
import '../domain/interest_category.dart';

/// İlgi alanı kataloğu okuma/yazma — `GET /api/ilgi-alanlari`,
/// `PUT /api/me/ilgi-alanlari`.
class InterestRepository {
  const InterestRepository(this._api);

  final BirlikteApiClient _api;

  Future<List<InterestCategoryItem>> fetchCatalog() async {
    final rows = (await _api.ilgiAlanlari()).cast<Map<String, dynamic>>();
    return [
      for (final r in rows)
        InterestCategoryItem(
          id: (r['ilgiAlaniId'] as num).toInt(),
          kod: (r['kod'] as String?) ?? '',
          ad: (r['ad'] as String?) ?? '',
          secili: r['secili'] as bool? ?? false,
        ),
    ];
  }

  Future<void> save(List<int> ilgiAlaniIdleri) =>
      _api.ilgiAlanlariniKaydet(ilgiAlaniIdleri);
}

final interestRepositoryProvider = Provider<InterestRepository>(
  (ref) => InterestRepository(ref.watch(birlikteApiClientProvider)),
);

final interestCatalogProvider = FutureProvider<List<InterestCategoryItem>>(
  (ref) => ref.watch(interestRepositoryProvider).fetchCatalog(),
);
