enum UserRole {
  superadmin,
  admin,
  user,
  subuser,
  team,
  driver,
  unknown;

  static UserRole fromBackend(String? value) {
    final v = (value ?? '').trim().toLowerCase().replaceAll('-', '').replaceAll('_', '');
    if (v.contains('super')) return UserRole.superadmin;
    if (v == 'admin' || v.contains('administrator')) return UserRole.admin;
    if (v.contains('subuser')) return UserRole.subuser;
    if (v.contains('team')) return UserRole.team;
    if (v.contains('driver')) return UserRole.driver;
    if (v.contains('user')) return UserRole.user;
    return UserRole.unknown;
  }

  String get backendValue => switch (this) {
        UserRole.superadmin => 'SUPERADMIN',
        UserRole.admin => 'ADMIN',
        UserRole.user => 'USER',
        UserRole.subuser => 'SUBUSER',
        UserRole.team => 'TEAM',
        UserRole.driver => 'DRIVER',
        UserRole.unknown => 'UNKNOWN',
      };
}
