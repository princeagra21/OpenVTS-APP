import 'package:fleet_stack/core/theme/open_vts_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePersistence {
  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);

    final savedBrand = prefs.getInt('brandColor');
    if (savedBrand == null) {
      final fallback = value
          ? OpenVtsTheme.defaultDarkBrand
          : OpenVtsTheme.defaultBrand;
      await prefs.setInt('brandColor', fallback.toARGB32());
    }
  }
}
