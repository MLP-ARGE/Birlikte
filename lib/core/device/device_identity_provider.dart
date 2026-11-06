import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import '../storage/secure_storage_service.dart';

/// birlikte-api'nin OTP doğrulamasında ve push bildirimde beklediği cihaz
/// kimliği.
///
/// PDKS entegrasyonundaki [PdksDeviceInfo]'dan farkı: `cihazId` burada
/// KALICI — her girişte aynı kalmalı, çünkü sunucu bunu tek-cihaz oturum
/// politikasında ("kapatılan cihazlar") kullanıyor. Rastgele üretip
/// atsaydık her girişte farklı bir cihazmış gibi görünürdük.
class BirlikteDeviceIdentity {
  const BirlikteDeviceIdentity({
    required this.cihazId,
    required this.cihazAdi,
    required this.platform,
  });

  /// Kalıcı, cihaza özgü UUID. İlk girişte üretilip Keychain/EncryptedPrefs'te
  /// saklanıyor; uygulama silinip yeniden kurulmadıkça değişmiyor.
  final String cihazId;

  /// Sunucuya gösterilecek okunur ad, örn. "iPhone 17".
  final String cihazAdi;

  /// "IOS" | "ANDROID" — API'nin beklediği sabit değerler.
  final String platform;
}

/// Cihaz kimliği, bir kez üretilip SecureStorage'da saklanıyor.
final deviceIdentityProvider = FutureProvider<BirlikteDeviceIdentity>((
  ref,
) async {
  final storage = ref.watch(secureStorageProvider);

  var id = await storage.readDeviceId();
  if (id == null) {
    id = const Uuid().v4();
    await storage.saveDeviceId(id);
  }

  final plugin = DeviceInfoPlugin();
  if (Platform.isIOS) {
    final ios = await plugin.iosInfo;
    return BirlikteDeviceIdentity(
      cihazId: id,
      cihazAdi: ios.name.isNotEmpty ? ios.name : ios.utsname.machine,
      platform: 'IOS',
    );
  }

  final android = await plugin.androidInfo;
  return BirlikteDeviceIdentity(
    cihazId: id,
    cihazAdi: '${android.manufacturer} ${android.model}',
    platform: 'ANDROID',
  );
});

/// Uygulama sürümü — otp/request'in ihtiyaç duymadığı ama /api/app/config
/// ve push-token kaydında işe yarayan bilgi.
final appVersionStringProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});
