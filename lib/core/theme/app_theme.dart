import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Persistent ThemeMode provider (defaults to Dark Glass Mode to match the
/// midnight glassy aesthetic, and toggles seamlessly between Light, Dark, and System).
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _boxName = 'app_settings';
  static const _key = 'theme_mode';

  ThemeModeNotifier() : super(_loadInitialTheme());

  static ThemeMode _loadInitialTheme() {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        final saved = Hive.box(_boxName).get(_key) as String?;
        if (saved == 'dark') return ThemeMode.dark;
        if (saved == 'system') return ThemeMode.system;
        if (saved == 'light') return ThemeMode.light;
      }
    } catch (_) {}
    return ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final box = Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : await Hive.openBox(_boxName);
      final val = mode == ThemeMode.light
          ? 'light'
          : (mode == ThemeMode.system ? 'system' : 'dark');
      await box.put(_key, val);
    } catch (_) {}
  }
}

/// 6 Interactive Style Presets matching "Choose your style" (Default, Ocean, Midnight, Sunset, Frosty, Emerald)
enum AppStylePreset {
  defaultBlue(
    id: 'default',
    label: 'Default',
    primary: Color(0xFF2B8CEE),
    secondary: Color(0xFF38BDF8),
    icon: Icons.radio_rounded,
  ),
  ocean(
    id: 'ocean',
    label: 'Ocean',
    primary: Color(0xFFF97316),
    secondary: Color(0xFFFBBF24),
    icon: Icons.water_drop_rounded,
  ),
  midnight(
    id: 'midnight',
    label: 'Midnight',
    primary: Color(0xFF7C3AED),
    secondary: Color(0xFFA855F7),
    icon: Icons.nightlight_round,
  ),
  sunset(
    id: 'sunset',
    label: 'Sunset',
    primary: Color(0xFFEC4899),
    secondary: Color(0xFFA855F7),
    icon: Icons.wb_twilight_rounded,
  ),
  frosty(
    id: 'frosty',
    label: 'Frosty',
    primary: Color(0xFF0EA5E9),
    secondary: Color(0xFF6366F1),
    icon: Icons.ac_unit_rounded,
  ),
  emerald(
    id: 'emerald',
    label: 'Emerald',
    primary: Color(0xFF10B981),
    secondary: Color(0xFF34D399),
    icon: Icons.eco_rounded,
  );

  final String id;
  final String label;
  final Color primary;
  final Color secondary;
  final IconData icon;

  const AppStylePreset({
    required this.id,
    required this.label,
    required this.primary,
    required this.secondary,
    required this.icon,
  });
}

final appStyleProvider = StateNotifierProvider<AppStyleNotifier, AppStylePreset>((ref) {
  return AppStyleNotifier();
});

class AppStyleNotifier extends StateNotifier<AppStylePreset> {
  static const _boxName = 'app_settings';
  static const _key = 'style_preset';

  AppStyleNotifier() : super(_loadInitial());

  static AppStylePreset _loadInitial() {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        final saved = Hive.box(_boxName).get(_key) as String?;
        for (final preset in AppStylePreset.values) {
          if (preset.id == saved) return preset;
        }
      }
    } catch (_) {}
    return AppStylePreset.defaultBlue;
  }

  Future<void> setPreset(AppStylePreset preset) async {
    state = preset;
    try {
      final box = Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : await Hive.openBox(_boxName);
      await box.put(_key, preset.id);
    } catch (_) {}
  }
}

class AppColors {
  // Glassy Light Theme Palette
  static const royalBlue = Color(0xFF2B8CEE);        // Luminous Broadcast Blue
  static const royalBlueDark = Color(0xFF0B111E);    // Deep Midnight Player Navy
  static const pinkAccent = Color(0xFFE11D48);       // Rose/Pink Accent
  static const lightBackground = Color(0xFFF4F7FB);  // Frosted Light Scaffold Background
  static const lightSurface = Color(0xFFFFFFFF);     // Pure White Glass Card Surface
  static const lightBorder = Color(0xFFE2E8F0);      // Subtle Light Specular Border
  static const lightTextPrimary = Color(0xFF0F172A); // Deep Slate Primary Text
  static const lightTextMuted = Color(0xFF64748B);   // Muted Slate Subtitle Text

  // Midnight Glass Dark Theme Palette (Matching Reference Screenshots)
  static const background = Color(0xFF0B101B);       // Deep Obsidian Midnight Scaffold
  static const surface = Color(0xFF131C2B);          // Glassy Slate Card Surface
  static const surfaceElevated = Color(0xFF1B263B);  // Elevated Glassy Pill Surface
  static const surfaceVariant = Color(0xFF26354D);   // Subtle Translucent Glass Border

  // Brand Accents (backward-compatible constants)
  static const primary = Color(0xFF2B8CEE);          // Luminous Sky/Royal Blue
  static const primaryDark = Color(0xFF1D4ED8);      // Deep Royal Blue
  static const accent = Color(0xFF38BDF8);           // Cyan/Sky Glow Accent
  static const emerald = Color(0xFF10B981);          // Emerald-500 live accent
  static const emeraldLight = Color(0xFF34D399);     // Emerald-400

  // Typography Colors
  static const onBackground = Color(0xFFF8FAFC);
  static const onSurface = Color(0xFFCBD5E1);
  static const onSurfaceMuted = Color(0xFF7E92B2);

  // Semantic Status Colors
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const gold = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const liveRed = Color(0xFFE11D48);

  // Reusable Gradients
  static const brandGradient = LinearGradient(
    colors: [Color(0xFF2B8CEE), Color(0xFF38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const emeraldGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroGradient = LinearGradient(
    colors: [Color(0xFF0B101B), Color(0xFF131C2B), Color(0xFF090D16)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Theme-aware helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color appBarBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF0B101B) : const Color(0xFFF4F7FB);

  static Color appBarFg(BuildContext context) =>
      isDark(context) ? Colors.white : const Color(0xFF0F172A);

  static Color scaffoldBg(BuildContext context) =>
      isDark(context) ? background : lightBackground;

  static Color cardBg(BuildContext context) =>
      isDark(context) ? surface : lightSurface;

  static Color glassCardBg(BuildContext context) =>
      isDark(context)
          ? const Color(0xFF141E2E).withValues(alpha: 0.88)
          : Colors.white.withValues(alpha: 0.94);

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? onBackground : lightTextPrimary;

  static Color textMuted(BuildContext context) =>
      isDark(context) ? const Color(0xFF8B9DBB) : lightTextMuted;

  static Color border(BuildContext context) =>
      isDark(context)
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFE2E8F0);

  /// Converts a 2-letter ISO country code (e.g. "TZ", "KE", "US") to its flag emoji.
  static String countryFlag(String? countryCode) {
    if (countryCode == null || countryCode.trim().length != 2) return '🌍';
    final code = countryCode.trim().toUpperCase();
    final int firstLetter = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondLetter = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
    if (firstLetter < 0x1F1E6 ||
        firstLetter > 0x1F1FF ||
        secondLetter < 0x1F1E6 ||
        secondLetter > 0x1F1FF) {
      return '🌍';
    }
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }
}

ThemeData buildLightTheme([AppStylePreset style = AppStylePreset.defaultBlue]) {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    colorScheme: ColorScheme.light(
      surface: AppColors.lightSurface,
      primary: style.primary,
      secondary: style.secondary,
      tertiary: AppColors.emerald,
      error: AppColors.error,
      onSurface: AppColors.lightTextPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightBackground,
      foregroundColor: AppColors.lightTextPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.lightTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.lightBorder),
      ),
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.lightSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.lightSurface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: style.primary, width: 1.6),
      ),
      hintStyle: const TextStyle(color: AppColors.lightTextMuted, fontSize: 13.5),
      labelStyle: const TextStyle(color: AppColors.lightTextPrimary, fontSize: 13.5),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w800),
      displayMedium: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w800),
      headlineLarge: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: AppColors.lightTextPrimary, height: 1.5),
      bodyMedium: TextStyle(color: AppColors.lightTextPrimary, height: 1.45),
      bodySmall: TextStyle(color: AppColors.lightTextMuted, fontSize: 12),
      labelLarge: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w700),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: style.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: style.primary,
        side: BorderSide(color: style.primary.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.lightTextPrimary,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: style.primary,
      unselectedItemColor: AppColors.lightTextMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}

ThemeData buildDarkTheme([AppStylePreset style = AppStylePreset.defaultBlue]) {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.dark(
      surface: AppColors.surface,
      primary: style.primary,
      secondary: style.secondary,
      tertiary: AppColors.emerald,
      error: AppColors.error,
      onSurface: AppColors.onBackground,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: style.primary, width: 1.6),
      ),
      hintStyle: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 13.5),
      labelStyle: const TextStyle(color: AppColors.onSurface, fontSize: 13.5),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.w800),
      displayMedium: TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.w800),
      headlineLarge: TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: AppColors.onSurface, height: 1.5),
      bodyMedium: TextStyle(color: AppColors.onSurface, height: 1.45),
      bodySmall: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12),
      labelLarge: TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.w700),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: style.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceElevated,
      contentTextStyle: const TextStyle(color: AppColors.onBackground, fontSize: 13.5, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: style.primary,
      unselectedItemColor: AppColors.onSurfaceMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}

ThemeData buildAppTheme() => buildDarkTheme();
