import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0F172A);       // slate-950
  static const surface = Color(0xFF1E293B);           // slate-800
  static const surfaceVariant = Color(0xFF334155);    // slate-700
  static const primary = Color(0xFF38BDF8);           // sky-400
  static const primaryDark = Color(0xFF0EA5E9);       // sky-500
  static const accent = Color(0xFF818CF8);            // indigo-400
  static const onBackground = Color(0xFFF1F5F9);      // slate-100
  static const onSurface = Color(0xFFCBD5E1);         // slate-300
  static const onSurfaceMuted = Color(0xFF64748B);    // slate-500
  static const success = Color(0xFF34D399);           // emerald-400
  static const warning = Color(0xFFFBBF24);           // amber-400
  static const error = Color(0xFFF87171);             // red-400
  static const liveRed = Color(0xFFEF4444);           // red-500
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.surface,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      error: AppColors.error,
      onSurface: AppColors.onBackground,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.onBackground,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: AppColors.onBackground),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.surfaceVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.surfaceVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      hintStyle: const TextStyle(color: AppColors.onSurfaceMuted),
      labelStyle: const TextStyle(color: AppColors.onSurface),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.w800),
      displayMedium: TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.w700),
      headlineLarge: TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: AppColors.onSurface),
      bodyMedium: TextStyle(color: AppColors.onSurface),
      bodySmall: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12),
      labelLarge: TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.w600),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.onSurfaceMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
