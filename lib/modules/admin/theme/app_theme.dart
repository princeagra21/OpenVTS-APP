import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  // BRAND COLORS
  static const Color defaultBrand = Color(0xFF000000); // Light mode default
  static const Color defaultDarkBrand = Colors.white;  // Dark mode default

  static const Color corporate = Color(0xFF0055FF);
  static const Color modern = Color(0xFF6A00FF);
  static const Color luxury = Color(0xFFB8933D);
  static const Color futuristic = Color(0xFF00FFFF);

  // STORED VALUES
  static bool isDarkMode = false;
  static Color brandColor = defaultBrand;

  // ----------------------------------------------------------------
  // LOAD THEME FROM STORAGE
  // ----------------------------------------------------------------
  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    isDarkMode = prefs.getBool("isDarkMode") ?? false;

    final savedBrand = prefs.getInt("brandColor");

    if (savedBrand != null) {
      // User previously selected a brand → restore it
      brandColor = Color(savedBrand);
    } else {
      // No saved brand → apply correct default for each mode
      brandColor = isDarkMode ? defaultDarkBrand : defaultBrand;
    }
  }

  // ----------------------------------------------------------------
  // SAVE DARK MODE
  // ----------------------------------------------------------------
  static Future<void> setDarkMode(bool value) async {
    isDarkMode = value;

    // Auto-fix brand color if still default black
    if (value && brandColor == defaultBrand) {
      brandColor = defaultDarkBrand;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isDarkMode", value);
    await prefs.setInt("brandColor", brandColor.value);
  }

  // ----------------------------------------------------------------
  // SAVE BRAND COLOR
  // ----------------------------------------------------------------
  static Future<void> setBrand(Color color) async {
    brandColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("brandColor", color.value);
  }

  // ----------------------------------------------------------------
  // PRIMARY TEXT COLOR LOGIC
  // ----------------------------------------------------------------
  static Color _getOnColor(Color color, {required bool isDark}) {
    if (isDark && color == defaultBrand) return Colors.white;
    final brightness = ThemeData.estimateBrightnessForColor(color);
    return brightness == Brightness.light ? Colors.black : Colors.white;
  }

  // ----------------------------------------------------------------
  // LIGHT THEME
  // ----------------------------------------------------------------
  static ThemeData light(Color brandColor) {
    final onPrimary = _getOnColor(brandColor, isDark: false);

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: brandColor,
      colorScheme: ColorScheme.light(
        primary: brandColor,
        secondary: brandColor,
        surface: Colors.white,
        onPrimary: onPrimary,
        onSecondary: onPrimary,
        onSurface: Colors.black,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F7F7),
      appBarTheme: AppBarTheme(
        backgroundColor: brandColor,
        foregroundColor: onPrimary,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: brandColor,
        foregroundColor: onPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: brandColor, width: 1.5),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: brandColor,
        unselectedLabelColor: Colors.black54,
        indicatorColor: brandColor,
      ),
    );
  }

  // ----------------------------------------------------------------
  // DARK THEME
  // ----------------------------------------------------------------
  static ThemeData dark(Color brandColor) {
    final onPrimary = _getOnColor(brandColor, isDark: true);

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: brandColor,
      colorScheme: ColorScheme.dark(
        primary: brandColor,
        secondary: brandColor,
        surface: const Color(0xFF121212),
        onPrimary: onPrimary,
        onSecondary: onPrimary,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF0E0E0E),
      appBarTheme: AppBarTheme(
        backgroundColor: brandColor,
        foregroundColor: onPrimary,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: brandColor,
        foregroundColor: onPrimary,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF1E1E1E),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: onPrimary,
        unselectedLabelColor: Colors.white60,
        indicatorColor: onPrimary,
      ),
    );
  }
}
