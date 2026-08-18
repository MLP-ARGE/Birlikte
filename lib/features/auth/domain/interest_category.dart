/// Kampanya kişiselleştirmesinde kullanılan ilgi alanları.
///
/// TODO(api): kategori listesi kampanya servisinden gelecek; Figma'daki
/// `interest-selection` ekranındaki 17 kategori sırasıyla burada.
abstract final class InterestCategories {
  /// En az bu kadar seçim yapılmadan devam edilemez (Figma açıklama metni).
  static const minimumSelection = 3;

  static const all = <String>[
    'Yeme & İçme',
    'Sağlık',
    'Eğitim',
    'Spor',
    'Teknoloji',
    'Müzik',
    'Sanat',
    'Seyahat',
    'Moda',
    'Sinema',
    'Kitap',
    'Oyun',
    'Doğa',
    'Fotoğrafçılık',
    'Yoga',
    'Dans',
    'Tarih',
  ];
}
