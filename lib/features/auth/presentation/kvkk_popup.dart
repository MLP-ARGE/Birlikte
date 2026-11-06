import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/birlikte_api/birlikte_api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

/// KVKK metnini okuyan tek yer — `WelcomePage`'deki onay kutusu işaretlenince
/// açılan popup. Daha önce ayrı bir tam ekrandı (`kvkk-onay` rotası); onay
/// zaten Welcome'daki kutu ile veriliyor, metni okumak isteyenler için ayrıca
/// bir "zorunlu ekran"a gerek yok — kutuyu işaretlemek tek başına yeterli.
///
/// GEÇİCİ TASARIM NOTU: `GET /api/kvkk/metin`'in tam yanıt şekli (başlık/
/// içerik alan adları) henüz doğrulanmadı — yalnızca `kvkkMetinId` alanının
/// var olduğu biliniyor. Bu yüzden metin İÇERİĞİ için birkaç olası alan adını
/// deniyor, hiçbiri tutmazsa genel bir başlık gösteriyoruz.
String? _firstString(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v is String && v.trim().isNotEmpty) return v;
  }
  return null;
}

void showKvkkPopup(BuildContext context, WidgetRef ref) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('KVKK Aydınlatma Metni', style: AppTypography.h4),
              const SizedBox(height: AppSpacing.s4),
              Flexible(
                child: FutureBuilder<List<dynamic>>(
                  future: ref.read(birlikteApiClientProvider).kvkkMetinleri(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.s6),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return Text(
                        'Metin yüklenemedi. Lütfen daha sonra tekrar dene.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      );
                    }
                    final metinler = snapshot.data ?? const [];
                    if (metinler.isEmpty) {
                      return Text(
                        'Gösterilecek metin bulunamadı.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      );
                    }
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final raw in metinler)
                            if (raw case Map<String, dynamic> m) ...[
                              Text(
                                _firstString(m, [
                                      'baslik',
                                      'metinBaslik',
                                      'ad',
                                    ]) ??
                                    'KVKK Metni ${m['kvkkMetinId']}',
                                style: AppTypography.h5,
                              ),
                              if (_firstString(m, [
                                    'metin',
                                    'icerik',
                                    'aciklama',
                                  ])
                                  case final body?) ...[
                                const SizedBox(height: AppSpacing.s2),
                                Text(
                                  body,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.s4),
                            ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Kapat'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// `verifyOtp()` başarılı olduğunda doldurulur; Welcome'daki onay kutusu
/// yalnızca bu `true` ise sunucuya `kvkkOnayGonder` çağrısı yapar.
class PendingKvkkOnay extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final pendingKvkkOnayProvider = NotifierProvider<PendingKvkkOnay, bool>(
  PendingKvkkOnay.new,
);

/// Onay kutusu işaretlendiğinde (yalnızca `kvkkOnayGerekli: true` ise, yani
/// backend metin güncellenip yeniden onay istediğinde) sunucuya gönderilir.
/// Her metni `kvkkMetinleri()`'nden tekrar çekip `onaylandi: true` ile
/// işaretliyor — kullanıcı popup'ı hiç açmasa da (metni okumak zorunlu
/// değil, yalnızca isteğe bağlı) onay kaydediliyor.
Future<void> sendKvkkOnayIfNeeded(WidgetRef ref) async {
  try {
    final metinler = await ref.read(birlikteApiClientProvider).kvkkMetinleri();
    final onaylar = [
      for (final raw in metinler)
        if (raw case Map<String, dynamic> m)
          {'kvkkMetinId': m['kvkkMetinId'], 'onaylandi': true},
    ];
    if (onaylar.isEmpty) return;
    await ref.read(birlikteApiClientProvider).kvkkOnayGonder(onaylar);
  } catch (_) {
    // Sessizce yutuluyor — oturum zaten kuruldu, KVKK onay kaydı bir
    // sonraki `BILGI_EKSIK`/`kvkkOnayGerekli` kontrolünde tekrar denenir.
  }
}
