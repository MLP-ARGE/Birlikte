import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Türkçe tarih/ay adları için locale verisi; olmadan DateFormat('tr_TR')
  // LocaleDataException atar.
  await initializeDateFormatting('tr_TR');
  Intl.defaultLocale = 'tr_TR';

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const ProviderScope(child: BirlikteApp()));
}
