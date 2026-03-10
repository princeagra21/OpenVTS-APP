class AdminDeviceListItem {
  final Map<String, dynamic> raw;

  const AdminDeviceListItem(this.raw);

  factory AdminDeviceListItem.fromRaw(Map<String, dynamic> raw) {
    return AdminDeviceListItem(raw);
  }

  String get id => _firstString(const ['id', 'deviceId', 'uid', '_id']);

  String get imei =>
      _firstString(const ['imei', 'imeiNumber', 'deviceImei', 'serialNo']);

  String get typeName {
    final nestedType = _asMap(raw['deviceType']);
    final value = _firstString(const ['deviceTypeName', 'type', 'name']);
    final nested = _string(nestedType['name']);
    if (nested.isNotEmpty) return nested;
    if (value.isNotEmpty) return value;
    return '—';
  }

  String get simNumber {
    final nestedSim = _asMap(raw['sim']);
    final nested = _string(
      nestedSim['simNumber'] ?? nestedSim['number'] ?? nestedSim['simNo'],
    );
    if (nested.isNotEmpty) return nested;

    final direct = _firstString(const ['simNumber', 'simNo', 'sim']);
    if (direct.isNotEmpty) return direct;

    return 'No SIM';
  }

  String get provider {
    final nestedSim = _asMap(raw['sim']);
    final nestedProvider = _asMap(nestedSim['provider']);

    final nested = _string(
      nestedProvider['name'] ??
          nestedSim['providerName'] ??
          raw['providerName'] ??
          raw['provider'],
    );
    if (nested.isNotEmpty) return nested;
    return '-';
  }

  String get rawStatus =>
      _firstString(const ['status', 'state', 'deviceStatus']);

  bool get isActive {
    final direct = _firstBool(const ['isActive', 'active', 'enabled']);
    if (direct != null) return direct;

    final normalized = normalizeStatus(rawStatus);
    if (normalized == 'inactive') return false;
    if (normalized == 'active') return true;
    if (normalized == 'maintenance') return false;

    return false;
  }

  String get statusLabel {
    final normalized = normalizeStatus(rawStatus, isActive: isActive);
    if (normalized == 'active') return 'Active';
    if (normalized == 'maintenance') return 'Maintenance';
    if (normalized == 'inactive') return 'Inactive';

    final rawValue = rawStatus.trim();
    if (rawValue.isNotEmpty) return rawValue;
    return 'Inactive';
  }

  String get expiryDate => _firstString(const [
    'expiry',
    'expiryDate',
    'licenseExpiry',
    'planExpiry',
    'validTill',
    'validTo',
  ]);

  String get statusFilterValue =>
      normalizeStatus(rawStatus, isActive: isActive);

  static String normalizeStatus(String? raw, {bool? isActive}) {
    final value = (raw ?? '').trim().toLowerCase();

    if (value.isEmpty) {
      if (isActive == true) return 'active';
      if (isActive == false) return 'inactive';
      return '';
    }

    if (value == 'enabled' || value == 'in_use' || value == 'active') {
      return 'active';
    }
    if (value == 'maintenance' || value == 'in_maintenance') {
      return 'maintenance';
    }
    if (value == 'inactive' || value == 'disabled' || value == 'disable') {
      return 'inactive';
    }

    if (value.contains('maint')) return 'maintenance';
    if (value.contains('active') || value.contains('enable') || value == 'up') {
      return 'active';
    }
    if (value.contains('disable') ||
        value.contains('inactive') ||
        value == 'down') {
      return 'inactive';
    }

    return value;
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }

  String _firstString(List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      final out = _string(value);
      if (out.isNotEmpty) return out;
    }
    return '';
  }

  bool? _firstBool(List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value == null) continue;
      if (value is bool) return value;
      if (value is num) return value != 0;
      final s = value.toString().trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
    }
    return null;
  }

  static String _string(Object? value) {
    if (value == null) return '';
    final out = value.toString().trim();
    if (out.isEmpty || out.toLowerCase() == 'null') return '';
    return out;
  }
}
