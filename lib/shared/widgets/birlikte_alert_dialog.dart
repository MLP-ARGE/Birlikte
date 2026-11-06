import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';

/// Uygulama genelinde TEK uyarı/bilgi diyaloğu standardı.
///
/// Ekran altında/alanların içinde kalıcı hata metni YOK — her uyarı,
/// bilgi ve hata mesajı bu diyalogla, ekranın ortasında gösteriliyor.
Future<void> showBirlikteAlert(
  BuildContext context, {
  required String title,
  String? message,
  String actionLabel = 'Tamam',
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Text(title, style: AppTypography.h4),
      content: message == null
          ? null
          : Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(actionLabel),
        ),
      ],
    ),
  );
}

/// Onay/iptal gerektiren diyaloglar (ör. çıkış yap) — aynı görsel standart,
/// `true`/`false` döner (dışına dokunarak kapatılırsa `null`).
Future<bool?> showBirlikteConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Vazgeç',
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Text(title, style: AppTypography.h4),
      content: Text(
        message,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            confirmLabel,
            style: AppTypography.buttonMedium.copyWith(
              color: destructive ? AppColors.textError : AppColors.textBrand,
            ),
          ),
        ),
      ],
    ),
  );
}
