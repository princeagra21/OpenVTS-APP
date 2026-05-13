import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/features/superadmin/data/mappers/superadmin_role_mapper.dart';
import 'package:open_vts/features/superadmin/data/mappers/superadmin_settings_mapper.dart';

void main() {
  test('SuperadminSettingsMapper maps settings fallback keys', () {
    const mapper = SuperadminSettingsMapper();
    final settings = mapper.settings(mapper.settingsFromResponse(_response(data: {
      'settings': {'language': 'en', 'themeMode': 'dark', 'units': 'KM'},
    })));

    expect(settings.language, 'en');
    expect(settings.theme, 'dark');
    expect(settings.units, 'KM');
  });

  test('SuperadminRoleMapper normalizes role permissions', () {
    const mapper = SuperadminRoleMapper();
    final roles = mapper.roleList(_response(data: {
      'roles': [
        {'id': 'r1', 'name': 'Manager', 'permissions': {'vehicles': 'manage'}},
      ],
    }));

    expect(roles.single.key, 'r1');
    expect(roles.single.permissions['vehicles'], 3);
  });
}

Map<String, Object?> _response({Object? data}) => <String, Object?>{
      'status': 'success',
      'data': <String, Object?>{'action': true, 'message': '', 'data': data},
    };
