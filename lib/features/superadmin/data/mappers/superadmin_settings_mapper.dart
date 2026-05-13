import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/features/superadmin/data/models/superadmin_settings_dtos.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_settings.dart';

class SuperadminSettingsMapper {
  const SuperadminSettingsMapper();

  SuperadminSettingsDto settingsFromResponse(Object? response) {
    final map = ApiResponseNormalizer.mapPayloadOf(response, preferredKeys: const ['settings', 'config', 'data']);
    return SuperadminSettingsDto.fromJson(map);
  }

  SuperadminSettingsData settings(SuperadminSettingsDto dto) {
    final json = dto.json;
    return SuperadminSettingsData(
      language: _text(_first(json, const ['language', 'lang', 'locale'])),
      dateFormat: _text(_first(json, const ['dateFormat', 'date_format', 'dateformat'])),
      use24Hour: _nullableBool(_first(json, const ['use24Hour', 'use_24_hour', 'use24hour'])),
      theme: _text(_first(json, const ['theme', 'themeMode', 'theme_mode'])),
      timezoneOffset: _text(_first(json, const ['timezoneOffset', 'timezone', 'timeZone', 'offset'])),
      units: _text(_first(json, const ['units', 'unit'])),
    );
  }

  Map<String, Object?> updatePayload(SuperadminSettingsData settings) => <String, Object?>{
        'language': settings.language,
        'dateFormat': settings.dateFormat,
        if (settings.use24Hour != null) 'use24Hour': settings.use24Hour,
        'theme': settings.theme,
        'timezoneOffset': settings.timezoneOffset,
        'units': settings.units,
      };

  static Object? _first(Map<String, Object?> source, List<String> keys) {
    for (final key in keys) {
      if (!source.containsKey(key)) continue;
      final value = source[key];
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      return value;
    }
    return null;
  }

  static String _text(Object? value) => value?.toString().trim() ?? '';
  static bool? _nullableBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = _text(value).toLowerCase();
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
    return null;
  }
}
