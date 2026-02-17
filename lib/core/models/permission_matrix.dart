enum PermissionLevel { full, manage, edit, view, none }

class PermissionMatrix {
  final Map<String, dynamic> raw;

  /// Normalized mapping from module key/name to permission level.
  final Map<String, PermissionLevel> levelsByModule;

  const PermissionMatrix({
    required this.raw,
    required this.levelsByModule,
  });

  /// Builds a matrix from a variety of common shapes:
  /// - Map: { tenants: "full", users: "view" }
  /// - List: [ { module: "tenants", level: "full" }, ... ]
  /// - Nested: { permissions: (map or list) }
  ///
  /// The output is normalized so that common module keys map to the UI labels:
  /// `Tenants`, `Users`, `Roles`, `Vehicles`, `Devices`, `SIM/APN`.
  static PermissionMatrix fromRaw(Object? data) {
    final raw = _coerceMap(data);
    final source = raw['permissions'] ?? raw['permission'] ?? raw['access'];

    final levels = <String, PermissionLevel>{};

    void add(String module, Object? level) {
      final canonical = _canonicalModuleLabel(module);
      if (canonical == null) return;
      levels[canonical] = _parseLevel(level) ?? PermissionLevel.none;
    }

    Object? root = source ?? data;
    if (root is Map) {
      for (final e in root.entries) {
        add(e.key.toString(), e.value);
      }
    } else if (root is List) {
      for (final it in root) {
        if (it is Map) {
          final module =
              (it['module'] ?? it['moduleKey'] ?? it['key'] ?? it['name'])
                  ?.toString();
          if (module == null) continue;
          final level = it['level'] ?? it['permission'] ?? it['access'];
          add(module, level);
        }
      }
    }

    return PermissionMatrix(raw: raw, levelsByModule: levels);
  }

  PermissionLevel? levelForModule(String moduleKeyOrName) {
    final k = moduleKeyOrName.trim();
    if (k.isEmpty) return null;
    if (levelsByModule.containsKey(k)) return levelsByModule[k];

    final canonical = _canonicalModuleLabel(k);
    if (canonical != null) return levelsByModule[canonical];
    return null;
  }

  static PermissionLevel? _parseLevel(Object? v) {
    if (v == null) return null;
    if (v is PermissionLevel) return v;
    if (v is num) {
      // Tolerant numeric mapping.
      // 0 none, 1 view, 2 edit, 3 manage, 4+ full.
      final n = v.toInt();
      if (n <= 0) return PermissionLevel.none;
      if (n == 1) return PermissionLevel.view;
      if (n == 2) return PermissionLevel.edit;
      if (n == 3) return PermissionLevel.manage;
      return PermissionLevel.full;
    }
    final s = v.toString().trim().toLowerCase();
    if (s.isEmpty) return null;
    if (s == 'full' || s == 'all' || s == 'admin') return PermissionLevel.full;
    if (s == 'manage' || s == 'write') return PermissionLevel.manage;
    if (s == 'edit' || s == 'update') return PermissionLevel.edit;
    if (s == 'view' || s == 'read') return PermissionLevel.view;
    if (s == 'none' || s == 'no' || s == 'deny') return PermissionLevel.none;
    return null;
  }

  static Map<String, dynamic> _coerceMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data.cast());
    return const <String, dynamic>{};
  }

  static String _normalizeModuleKey(String s) {
    return s.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  static String? _canonicalModuleLabel(String moduleKeyOrName) {
    final n = _normalizeModuleKey(moduleKeyOrName);
    if (n.isEmpty) return null;

    // Direct UI label matches.
    const canonical = <String, String>{
      'tenants': 'Tenants',
      'tenant': 'Tenants',
      'users': 'Users',
      'user': 'Users',
      'roles': 'Roles',
      'role': 'Roles',
      'vehicles': 'Vehicles',
      'vehicle': 'Vehicles',
      'devices': 'Devices',
      'device': 'Devices',
      'simapn': 'SIM/APN',
      'sim': 'SIM/APN',
      'apn': 'SIM/APN',
      'simapns': 'SIM/APN',
    };

    // Common backend keys (tolerant).
    if (canonical.containsKey(n)) return canonical[n];
    if (n.contains('tenant')) return 'Tenants';
    if (n.contains('user')) return 'Users';
    if (n.contains('role')) return 'Roles';
    if (n.contains('vehicle')) return 'Vehicles';
    if (n.contains('device')) return 'Devices';
    if (n.contains('sim') || n.contains('apn')) return 'SIM/APN';

    // Ignore unknown modules to keep UI stable.
    return null;
  }
}

extension PermissionLevelUiX on PermissionLevel {
  String get uiLabel {
    return switch (this) {
      PermissionLevel.full => 'Full',
      PermissionLevel.manage => 'Manage',
      PermissionLevel.edit => 'Edit',
      PermissionLevel.view => 'View',
      PermissionLevel.none => 'None',
    };
  }
}
