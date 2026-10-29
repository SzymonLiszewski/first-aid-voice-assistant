import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFFC62828);
  static const Color primaryDark = Color(0xFFB71C1C);
  static const Color primarySoft = Color(0xFFFDECEC);
  static const Color background = Color(0xFFF6F6F7);
  static const Color surface = Colors.white;
  static const Color text = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF555555);
  static const Color divider = Color(0xFFEEEEF0);
  static const Color userBubble = Color(0xFF2B2B2E);

  static const Color demoBackground = Color(0xFFFFF3D6);
  static const Color demoBorder = Color(0xFFF0C36A);
  static const Color demoText = Color(0xFF6B4000);

  static const Color ok = Color(0xFF2E7D32);
  static const Color busy = Color(0xFFE65100);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.background,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );
}
