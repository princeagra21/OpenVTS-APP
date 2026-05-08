import 'package:flutter/foundation.dart';

enum LocalizationRole { admin, superadmin, user }

@immutable
class LocalizationPermissions {
  const LocalizationPermissions({
    this.requireDirtyBeforeSave = false,
    this.includeThemeInPayload = false,
    this.preferEnglishDefaultLanguage = false,
    this.hasLocalizationSettingsEndpoint = true,
  });

  final bool requireDirtyBeforeSave;
  final bool includeThemeInPayload;
  final bool preferEnglishDefaultLanguage;
  final bool hasLocalizationSettingsEndpoint;
}

@immutable
class LocalizationSettingsData {
  const LocalizationSettingsData({
    required this.languageCode,
    required this.direction,
    required this.dateFormat,
    required this.timeFormat,
    required this.use24Hour,
    required this.timezone,
    required this.units,
    required this.mapLat,
    required this.mapLng,
    required this.mapZoom,
  });

  final String languageCode;
  final String direction;
  final String dateFormat;
  final String timeFormat;
  final bool? use24Hour;
  final String timezone;
  final String units;
  final double? mapLat;
  final double? mapLng;
  final int? mapZoom;
}

@immutable
class LocalizationSnapshot {
  const LocalizationSnapshot({
    required this.selectedLanguage,
    required this.textDirection,
    required this.dateFormat,
    required this.timeFormat,
    required this.timezone,
    required this.units,
    required this.lat,
    required this.lng,
    required this.zoom,
  });

  final String selectedLanguage;
  final String textDirection;
  final String dateFormat;
  final String timeFormat;
  final String timezone;
  final String units;
  final double lat;
  final double lng;
  final int zoom;

  @override
  bool operator ==(Object other) {
    return other is LocalizationSnapshot &&
        other.selectedLanguage == selectedLanguage &&
        other.textDirection == textDirection &&
        other.dateFormat == dateFormat &&
        other.timeFormat == timeFormat &&
        other.timezone == timezone &&
        other.units == units &&
        other.lat == lat &&
        other.lng == lng &&
        other.zoom == zoom;
  }

  @override
  int get hashCode => Object.hash(
    selectedLanguage,
    textDirection,
    dateFormat,
    timeFormat,
    timezone,
    units,
    lat,
    lng,
    zoom,
  );
}

@immutable
class LocalizationSaveResult {
  const LocalizationSaveResult._({
    required this.success,
    required this.message,
  });

  const LocalizationSaveResult.success(String message)
    : this._(success: true, message: message);

  const LocalizationSaveResult.failure(String message)
    : this._(success: false, message: message);

  const LocalizationSaveResult.idle() : this._(success: false, message: null);

  final bool success;
  final String? message;
}
