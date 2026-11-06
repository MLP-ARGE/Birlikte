/// Kampanya kişiselleştirmesinde kullanılan ilgi alanı kataloğu.
///
/// Sabit, kodlanmış bir liste değil: `GET /api/ilgi-alanlari`'den gelen 13
/// kayıt (SAGLIK, SPOR, BESLENME, ANNE_COCUK, EGITIM, SEYAHAT, YEME_ICME,
/// ALISVERIS, TEKNOLOJI, KULTUR_SANAT, EV_YASAM, OTOMOTIV, FINANS).
class InterestCategoryItem {
  const InterestCategoryItem({
    required this.id,
    required this.kod,
    required this.ad,
    this.secili = false,
  });

  final int id;
  final String kod;
  final String ad;

  /// Oturum sahibinin daha önce seçip seçmediği — ekran ilk açıldığında
  /// seçili kümeyi buradan kurar.
  final bool secili;
}

abstract final class InterestCategories {
  /// En az bu kadar seçim yapılmadan devam edilemez (Figma açıklama metni).
  static const minimumSelection = 3;
}
