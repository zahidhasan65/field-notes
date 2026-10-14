import 'package:flutter/material.dart';
import 'app_colors.dart';

ThemeData buildTheme({Brightness brightness = Brightness.light}) {
  final dark = brightness == Brightness.dark;
  final pal = dark ? AppPalette.dark : AppPalette.light;
  final radius = BorderRadius.circular(12);

  OutlineInputBorder border(Color c) =>
      OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: c));

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    extensions: [pal],
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      surface: pal.surface,
      onSurface: pal.text,
    ),
    scaffoldBackgroundColor: pal.bg,
    dividerTheme: DividerThemeData(color: pal.border),
    appBarTheme: AppBarTheme(
      backgroundColor: pal.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: pal.text,
      titleTextStyle: TextStyle(color: pal.text, fontSize: 18, fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: pal.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      border: border(pal.border),
      enabledBorder: border(pal.border),
      focusedBorder: border(AppColors.primary),
      errorBorder: border(AppColors.red),
      focusedErrorBorder: border(AppColors.red),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: pal.text,
        side: BorderSide(color: pal.border),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: pal.surface,
      indicatorColor: AppColors.primary.withOpacity(.14),
      labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ),
  );
}
