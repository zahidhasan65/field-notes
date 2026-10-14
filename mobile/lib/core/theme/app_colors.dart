import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF1E6BE6);
  static const primaryDark = Color(0xFF1250B8);
  static const bg = Color(0xFFF4F7FC);
  static const border = Color(0xFFE6EBF3);
  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const green = Color(0xFF16A36A);
  static const orange = Color(0xFFF59E0B);
  static const red = Color(0xFFE5484D);

  static const headerGradient = LinearGradient(
    colors: [Color(0xFF2B7BFF), primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const brandGradient = LinearGradient(
    colors: [primary, green],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}


@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.surface,
    required this.bg,
    required this.border,
    required this.text,
    required this.muted,
  });

  final Color surface; // cards, inputs, sheets
  final Color bg; // screen background
  final Color border;
  final Color text;
  final Color muted;

  static const light = AppPalette(
    surface: Colors.white,
    bg: Color(0xFFF4F7FC),
    border: Color(0xFFE6EBF3),
    text: Color(0xFF0F172A),
    muted: Color(0xFF64748B),
  );

  static const dark = AppPalette(
    surface: Color(0xFF1B2433),
    bg: Color(0xFF0F1623),
    border: Color(0xFF2B3649),
    text: Color(0xFFE6EBF5),
    muted: Color(0xFF98A4B8),
  );

  @override
  AppPalette copyWith({
    Color? surface,
    Color? bg,
    Color? border,
    Color? text,
    Color? muted,
  }) =>
      AppPalette(
        surface: surface ?? this.surface,
        bg: bg ?? this.bg,
        border: border ?? this.border,
        text: text ?? this.text,
        muted: muted ?? this.muted,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      surface: Color.lerp(surface, other.surface, t)!,
      bg: Color.lerp(bg, other.bg, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get pal => Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
