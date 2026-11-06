import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Firebase config dosyaları (google-services.json /
    // GoogleService-Info.plist) henüz projeye eklenmedi; push bildirimleri
    // bunlar olmadan çalışmaz ama uygulamanın geri kalanı etkilenmemeli.
    debugPrint('Firebase başlatılamadı (push bildirimleri devre dışı): $e');
  }

  // Türkçe tarih/ay adları için locale verisi; olmadan DateFormat('tr_TR')
  // LocaleDataException atar.
  await initializeDateFormatting('tr_TR');
  Intl.defaultLocale = 'tr_TR';

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      // Oturum cihazda şifreli depoda tutulur; uygulama yeniden açılınca
      // kullanıcı tekrar giriş yapmak zorunda kalmaz.
      autoRefreshToken: true,
    ),
  );

  runApp(const ProviderScope(child: BirlikteApp()));
}
