import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Uygulamanın gerçek sürümü, "1.0.0 (9)" biçiminde.
///
/// Değer pubspec'ten derlemeye gömülüyor ve buradan okunuyor; elle yazılan
/// bir sabit tutulmuyor ki sürümler birbirinden kaymasın.
///
/// Derleme numarası da gösteriliyor: beta testçileri hata bildirirken hangi
/// TestFlight yapısında olduklarını söyleyebilsin diye.
/// Hata fırlatmıyor. Paket üst verisi okunamazsa (platform eklentisi yoksa)
/// boş dize dönüyor: fırlatsaydı Riverpod yeniden deneme zamanlayıcısı kurar
/// ve sürüm satırı gibi tamamen ikincil bir bilgi için sürekli uğraşırdı.
final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    final build = info.buildNumber;
    return build.isEmpty ? info.version : '${info.version} ($build)';
  } catch (_) {
    return '';
  }
});
