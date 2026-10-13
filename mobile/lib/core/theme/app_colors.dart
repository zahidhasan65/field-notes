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
