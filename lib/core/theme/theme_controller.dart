import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized runtime theme, brand, text direction, and units controller.
///
/// This keeps the existing visual behavior intact while removing bootstrap
/// logic from `main.dart`, so app startup follows the architecture rule:
/// `main.dart` bootstraps, `app.dart` renders the app, `core/` owns shared
/// infrastructure.
class ThemeController extends ChangeNotifier {
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(
    ThemeMode.light,
  );
  final ValueNotifier<Color> brandColor = ValueNotifier<Color>(
    OpenVtsTheme.defaultBrand,
  );
  final ValueNotifier<TextDirection> textDirection =
      ValueNotifier<TextDirection>(TextDirection.ltr);
  final ValueNotifier<String> units = ValueNotifier<String>('KM');

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final isDark = prefs.getBool('isDark') ?? false;
    final modeRaw = prefs.getString('themeMode');
    final colorValue =
        prefs.getInt('brandColor') ?? OpenVtsTheme.defaultBrand.toARGB32();
    final directionRaw =
        prefs.getString('layoutDirection') ?? prefs.getString('direction');
    final unitsRaw = prefs.getString('units') ?? 'KM';

    themeMode.value = switch (modeRaw) {
      'system' => ThemeMode.system,
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => isDark ? ThemeMode.dark : ThemeMode.light,
    };

    var nextBrand = Color(colorValue);
    final isLightMode = themeMode.value != ThemeMode.dark && !isDark;
    if (isLightMode &&
        ThemeData.estimateBrightnessForColor(nextBrand) == Brightness.light) {
      nextBrand = OpenVtsTheme.defaultBrand;
      await prefs.setInt('brandColor', nextBrand.toARGB32());
    }

    brandColor.value = nextBrand;
    textDirection.value = (directionRaw ?? '').trim().toUpperCase() == 'RTL'
        ? TextDirection.rtl
        : TextDirection.ltr;
    units.value = _normalizeUnits(unitsRaw);
    notifyListeners();
  }

  Future<void> setDarkMode(bool isDark) async {
    await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;

    if (mode == ThemeMode.dark &&
        brandColor.value == OpenVtsTheme.defaultBrand) {
      brandColor.value = OpenVtsTheme.defaultDarkBrand;
    } else if (mode == ThemeMode.light &&
        brandColor.value == OpenVtsTheme.defaultDarkBrand) {
      brandColor.value = OpenVtsTheme.defaultBrand;
    }

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'themeMode',
      switch (mode) {
        ThemeMode.system => 'system',
        ThemeMode.dark => 'dark',
        ThemeMode.light => 'light',
      },
    );
    await prefs.setBool('isDark', mode == ThemeMode.dark);
    await prefs.setInt('brandColor', brandColor.value.toARGB32());
  }

  Future<void> setBrand(Color color) async {
    brandColor.value = color;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('brandColor', color.toARGB32());
  }

  Future<void> setTextDirection(String direction) async {
    final normalized = direction.trim().toUpperCase() == 'RTL' ? 'RTL' : 'LTR';
    textDirection.value = normalized == 'RTL'
        ? TextDirection.rtl
        : TextDirection.ltr;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('layoutDirection', normalized);
    await prefs.setString('direction', normalized);
  }

  Future<void> setUnits(String value) async {
    final normalized = _normalizeUnits(value);
    units.value = normalized;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('units', normalized);
  }

  String _normalizeUnits(String value) {
    final v = value.trim().toUpperCase();
    if (v == 'MILES' || v == 'MILE' || v == 'MI') return 'MILES';
    return 'KM';
  }
}

final themeController = ThemeController();
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
