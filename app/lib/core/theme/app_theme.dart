import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/theme/app_typography.dart';

/// Construit les deux ThemeData de l'application à partir de [LyPalette].
///
/// Material 3 sert de base ; tout ce qui est visible vient des tokens.
abstract final class LyTheme {
  static ThemeData light() => _build(LyPalette.light, Brightness.light);

  static ThemeData dark() => _build(LyPalette.dark, Brightness.dark);

  static ThemeData _build(LyPalette p, Brightness brightness) {
    final texts = LyType.textTheme(p.textPrimary, p.textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: LyType.family,
      scaffoldBackgroundColor: p.surface,
      canvasColor: p.surface,
      splashFactory: InkSparkle.splashFactory,
      extensions: [p],
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: p.primary,
            brightness: brightness,
          ).copyWith(
            primary: p.primary,
            onPrimary: p.onPrimary,
            surface: p.surface,
            onSurface: p.textPrimary,
            error: p.danger,
          ),
      textTheme: texts,
      iconTheme: IconThemeData(
        color: p.textPrimary,
        size: LyIconSize.large,
        weight: LyIconSize.stroke,
      ),
      dividerTheme: DividerThemeData(
        color: p.cardBorder,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: texts.headlineSmall,
        iconTheme: IconThemeData(color: p.textPrimary, size: LyIconSize.large),
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.card,
        shape: const RoundedRectangleBorder(borderRadius: LyRadius.sheetR),
        showDragHandle: true,
        dragHandleColor: p.cardBorder,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LyRadius.hero),
        ),
        titleTextStyle: texts.titleLarge,
        contentTextStyle: texts.bodyMedium?.copyWith(color: p.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.textPrimary,
        contentTextStyle: texts.bodyMedium?.copyWith(color: p.surface),
        actionTextColor: p.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LyRadius.button),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          minimumSize: const Size.fromHeight(54),
          textStyle: texts.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LyRadius.pill),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: texts.labelMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          side: BorderSide(color: p.cardBorder),
          minimumSize: const Size.fromHeight(52),
          textStyle: texts.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LyRadius.pill),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.onPrimary : p.card,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.primary : p.chipFill,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Colors.transparent
              : p.cardBorder,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
