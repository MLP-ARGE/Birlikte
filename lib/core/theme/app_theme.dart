import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_typography.dart';

/// Uygulama teması (Figma: MLPCARE BIRLIKTE).
///
/// Şu an yalnızca **açık tema** vardır. Figma'da koyu tema "2. Theme"
/// değişken koleksiyonunda tanımlı; Variables REST API'si Enterprise plan
/// gerektirdiği için o değerler okunamadı. Koyu tema değerleri elde edilene
/// kadar uydurmak yerine tek moda sabitlendi — [BirlikteApp] themeMode'u
/// light'ta tutar.
abstract final class AppTheme {
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.actionPrimary,
      onPrimary: AppColors.textOnBrand,
      primaryContainer: AppColors.surfaceBrand,
      onPrimaryContainer: AppColors.textBrand,
      secondary: AppColors.brand,
      onSecondary: AppColors.textOnBrand,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.surfaceSubtle,
      surfaceContainer: AppColors.surfaceSunken,
      onSurfaceVariant: AppColors.textSecondary,
      error: AppColors.actionDestructive,
      onError: AppColors.textOnBrand,
      errorContainer: AppColors.statusErrorSubtle,
      onErrorContainer: AppColors.textError,
      outline: AppColors.borderDefault,
      outlineVariant: AppColors.borderStrong,
      inverseSurface: AppColors.surfaceInverse,
      onInverseSurface: AppColors.surface,
    );

    final textTheme = AppTypography.textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppTypography.sans,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.title,
        iconTheme: const IconThemeData(
          color: AppColors.iconDefault,
          size: AppSize.icon,
        ),
      ),

      iconTheme: const IconThemeData(
        color: AppColors.iconDefault,
        size: AppSize.icon,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.borderDefault,
        thickness: 1,
        space: 1,
      ),

      // Figma kuralı: liste kartlarında gölge yok — border ile ayrılır.
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.borderDefault),
        ),
      ),

      // Buton varyantları pill (radius.full) ve 52/48/40 yüksekliktedir.
      // Varyant matrisinin tamamı BirlikteButton widget'ında; buradaki
      // temalar Material widget'ları doğrudan kullanıldığında devreye girer.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.actionPrimary,
          foregroundColor: AppColors.textOnBrand,
          disabledBackgroundColor: AppColors.actionDisabled,
          disabledForegroundColor: AppColors.textDisabled,
          minimumSize: const Size.fromHeight(AppSize.buttonLarge),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSize.buttonPadHLarge,
          ),
          textStyle: AppTypography.buttonLarge,
          shape: const StadiumBorder(),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          disabledForegroundColor: AppColors.textDisabled,
          minimumSize: const Size.fromHeight(AppSize.buttonLarge),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSize.buttonPadHLarge,
          ),
          textStyle: AppTypography.buttonLarge,
          side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
          shape: const StadiumBorder(),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textBrand,
          textStyle: AppTypography.buttonMedium,
          shape: const StadiumBorder(),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s5,
          vertical: AppSpacing.s4,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        errorStyle: AppTypography.caption.copyWith(color: AppColors.textError),
        border: _inputBorder(AppColors.borderDefault),
        enabledBorder: _inputBorder(AppColors.borderDefault),
        focusedBorder: _inputBorder(AppColors.borderFocus, width: 1.5),
        errorBorder: _inputBorder(AppColors.borderError),
        focusedErrorBorder: _inputBorder(AppColors.borderError, width: 1.5),
        disabledBorder: _inputBorder(AppColors.borderDefault),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceSunken,
        selectedColor: AppColors.surfaceBrand,
        side: const BorderSide(color: AppColors.borderDefault),
        labelStyle: AppTypography.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.textBrand,
        unselectedItemColor: AppColors.iconSubtle,
        selectedLabelStyle: AppTypography.labelSmall,
        unselectedLabelStyle: AppTypography.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: AppTypography.h4,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceInverse,
        contentTextStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.surface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(AppColors.surface),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.actionPrimary
              : AppColors.borderStrong,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.actionPrimary
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.textOnBrand),
        side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.actionPrimary,
        linearTrackColor: AppColors.surfaceSunken,
        circularTrackColor: AppColors.surfaceSunken,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.textBrand,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTypography.labelLarge,
        unselectedLabelStyle: AppTypography.labelLarge,
        indicatorColor: AppColors.borderBrand,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppColors.borderDefault,
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.iconDefault,
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.s5),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: color, width: width),
      );
}
