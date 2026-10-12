import 'package:flutter/material.dart';

/// Nom de l'application : à changer ici uniquement
const String kAppName = 'Soukna';

/// Police (voir l'étape « Police Outfit » plus bas ; sans elle, la police par défaut est utilisée)
const String kFontFamily = 'Outfit';

class AppColors {
  static const ink = Color(0xFF2B2A4C); // indigo profond
  static const coral = Color(0xFFFF7A6B);
  static const bg = Color(0xFFFFF3EC); // pêche très clair
  static const mint = Color(0xFFD7F2E6);
  static const lilac = Color(0xFFE6DFFF);
  static const peach = Color(0xFFFFDCCC);
  static const sky = Color(0xFFD6E8FF);
  static const muted = Color(0xFF6C6A8A);
  static const line = Color(0xFFEBDDD3);
  static const olive = Color(0xFF2E7D5B);
  static const harissa = Color(0xFFD1342C);

  static const tints = [mint, lilac, peach, sky];

  /// Couleur pastel stable pour un produit (selon son nom)
  static Color tintFor(String name) =>
      tints[name.codeUnits.fold<int>(0, (a, b) => a + b) % tints.length];

  // alias de compatibilité avec les anciens fichiers
  static const primary = ink;
  static const blue = ink;
  static const blueDeep = ink;
  static const saffron = coral;
  static const accent = coral;
  static const wall = bg;
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.ink).copyWith(
    primary: AppColors.ink,
    onPrimary: Colors.white,
    secondary: AppColors.coral,
    onSecondary: AppColors.ink,
    error: AppColors.harissa,
    surface: Colors.white,
    onSurface: AppColors.ink,
  );

  final base = ThemeData(
      useMaterial3: true, colorScheme: scheme, fontFamily: kFontFamily);
  final text = base.textTheme
      .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);

  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: c, width: w),
      );

  return base.copyWith(
    textTheme: text,
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: kFontFamily,
        color: AppColors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      hintStyle: const TextStyle(color: AppColors.muted),
      border: border(AppColors.line),
      enabledBorder: border(AppColors.line),
      focusedBorder: border(AppColors.ink, 1.6),
      errorBorder: border(AppColors.harissa),
      focusedErrorBorder: border(AppColors.harissa, 1.6),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
            fontFamily: kFontFamily, fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.ink, width: 1.4),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
            fontFamily: kFontFamily, fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        textStyle: const TextStyle(
            fontFamily: kFontFamily, fontWeight: FontWeight.w700),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    badgeTheme: const BadgeThemeData(
      backgroundColor: AppColors.ink,
      textColor: Colors.white,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.coral,
      foregroundColor: AppColors.ink,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(color: Colors.white),
      actionTextColor: AppColors.coral,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, space: 1),
  );
}