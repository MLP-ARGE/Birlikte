import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget testlerinde gerçek fontları yükler.
///
/// Yüklenmezse test sahte "Ahem" fontunu kullanır: metin ölçüleri gerçeği
/// yansıtmaz (satır sarmaları değişir, taşma uyarıları çıkar) ve ikonlar boş
/// kare olarak render edilir. Golden alan her test bunu çağırmalı.
Future<void> loadAppFonts() async {
  // institution-match ekranı DateFormat('tr_TR') kullanıyor; locale verisi
  // yüklenmezse LocaleDataException atar (main.dart'taki kurulumun eşi).
  await initializeDateFormatting('tr_TR');
  Intl.defaultLocale = 'tr_TR';

  Future<void> fromFile(String family, String path) async {
    final loader = FontLoader(family)
      ..addFont(File(path).readAsBytes().then((b) => b.buffer.asByteData()));
    await loader.load();
  }

  Future<void> fromBundle(String family, String key) async {
    final loader = FontLoader(family)..addFont(rootBundle.load(key));
    await loader.load();
  }

  await fromFile('Inter', 'assets/fonts/Inter-Variable.ttf');
  await fromFile('JetBrainsMono', 'assets/fonts/JetBrainsMono-Variable.ttf');

  // AppIcons yalnızca 300 ağırlığını kullanıyor (bkz. app_icons.dart).
  await fromBundle(
    'packages/lucide_icons_flutter/Lucide300',
    'packages/lucide_icons_flutter/assets/build_font/LucideVariable-w300.ttf',
  );
}
