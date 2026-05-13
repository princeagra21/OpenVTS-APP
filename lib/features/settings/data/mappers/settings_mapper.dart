import 'package:open_vts/features/settings/data/models/settings_response.dart';
import 'package:open_vts/features/settings/domain/entities/settings_snapshot.dart';

class SettingsMapper {
  const SettingsMapper();

  SettingsSnapshot toDomain(SettingsResponse response) {
    final source = response.data;
    final nested = source['data'];
    if (nested is Map) return SettingsSnapshot(values: Map<String, Object?>.from(nested.cast()));
    return SettingsSnapshot(values: Map<String, Object?>.from(source));
  }
}
