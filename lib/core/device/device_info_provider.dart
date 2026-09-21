import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// PDKS'nin her istekte beklediği cihaz başlıkları.
///
/// Sunucu bu bilgilere göre davranabildiği (sürüm kontrolü, cihaz kaydı)
/// için gerçek değerleri gönderiyoruz. Edge Function bunları alıp PDKS'ye
/// aktarıyor; uygulama PDKS'ye doğrudan istek atmıyor.
class PdksDeviceInfo {
  const PdksDeviceInfo({
    required this.deviceTypeId,
    required this.appVersion,
    required this.manufacturer,
    required this.model,
    required this.osVersion,
  });

  final String deviceTypeId;
  final String appVersion;
  final String manufacturer;
  final String model;
  final String osVersion;

  Map<String, dynamic> toJson() => {
    'deviceTypeId': deviceTypeId,
    'appVersion': appVersion,
    'manufacturer': manufacturer,
    'model': model,
    'osVersion': osVersion,
  };
}

/// Cihaz bilgisi platform kanalı üzerinden geliyor; bir kez okunup
/// önbelleğe alınıyor (her giriş denemesinde yeniden sormaya gerek yok).
final deviceInfoProvider = FutureProvider<PdksDeviceInfo>((ref) async {
  final package = await PackageInfo.fromPlatform();
  final plugin = DeviceInfoPlugin();

  if (Platform.isIOS) {
    final ios = await plugin.iosInfo;
    return PdksDeviceInfo(
      deviceTypeId: 'IOS',
      appVersion: package.version,
      manufacturer: 'Apple',
      // utsname.machine ham model kodu verir (örn. "iPhone15,2"); PDKS'ye
      // okunur adı göndermek daha yararlı.
      model: ios.utsname.machine,
      osVersion: ios.systemVersion,
    );
  }

  final android = await plugin.androidInfo;
  return PdksDeviceInfo(
    deviceTypeId: 'ANDROID',
    appVersion: package.version,
    manufacturer: android.manufacturer,
    model: android.model,
    osVersion: '${android.version.sdkInt}',
  );
});
