import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../birlikte_api/birlikte_api_client.dart';
import '../birlikte_api/birlikte_session_provider.dart';

/// `POST /api/me/acilis` — backend kullanıcının kurulu sürümünü takip etmek
/// için bunu uygulama her açıldığında (soğuk başlangıç + arka plandan dönüş)
/// istiyor. Oturum yoksa ya da ağ/sunucu hatası olursa sessizce yutuluyor —
/// bu salt bilgilendirici bir çağrı, kullanıcı akışını etkilememeli.
Future<void> recordAppOpen(Ref ref) async {
  if (!ref.read(birlikteSessionProvider)) return;
  try {
    final version = (await PackageInfo.fromPlatform()).version;
    await ref.read(birlikteApiClientProvider).recordAppOpen(surum: version);
  } catch (_) {
    // sessizce yutuluyor
  }
}

/// Uygulama ön plana her döndüğünde (`resumed`) [recordAppOpen] tetikler.
/// Soğuk başlangıç [ensureAppOpenRecorded] ile ayrı ele alınıyor —
/// `AppLifecycleListener.onResume` ilk açılışta çağrılmıyor.
///
/// `BirlikteApp.build()`'de bir kez `ref.watch` edilerek uygulama ömrü
/// boyunca canlı tutuluyor.
final appOpenLifecycleProvider = Provider<void>((ref) {
  final listener = AppLifecycleListener(
    onResume: () => unawaited(recordAppOpen(ref)),
  );
  ref.onDispose(listener.dispose);
});

class _AppOpenRecorded extends Notifier<bool> {
  @override
  bool build() => false;

  void markDone() => state = true;
}

final _appOpenRecordedProvider = NotifierProvider<_AppOpenRecorded, bool>(
  _AppOpenRecorded.new,
);

/// Çıkışta çağrılır — bayrak sıfırlanmazsa bir sonraki (farklı hesap olası)
/// girişte açılış kaydı hiç gönderilmez.
void resetAppOpenRecordedFlag(Ref ref) {
  ref.invalidate(_appOpenRecordedProvider);
}

/// Soğuk başlangıç için oturum başına bir kez — Welcome/Home `build()`'inde
/// çağrılır. `missing_info_sheet.dart`/`push_notification_service.dart` ile
/// aynı desen: bayrak `build()` SIRASINDA değil `addPostFrameCallback`
/// içinde işaretleniyor.
void ensureAppOpenRecorded(WidgetRef ref) {
  if (ref.read(_appOpenRecordedProvider)) return;
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (ref.read(_appOpenRecordedProvider)) return;
    ref.read(_appOpenRecordedProvider.notifier).markDone();
    if (!ref.read(birlikteSessionProvider)) return;
    try {
      final version = (await PackageInfo.fromPlatform()).version;
      await ref.read(birlikteApiClientProvider).recordAppOpen(surum: version);
    } catch (_) {
      // sessizce yutuluyor
    }
  });
}
