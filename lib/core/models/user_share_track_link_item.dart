class UserShareTrackLinkItem {
  final Map<String, dynamic> raw;

  const UserShareTrackLinkItem(this.raw);

  String get id => _text(raw['id'] ?? raw['_id'] ?? raw['shareTrackId']);

  String get uniqueCode => _text(raw['uniqueCode'] ?? raw['code']);

  String get finalUrl =>
      _text(raw['finalUrl'] ?? raw['url'] ?? raw['link'] ?? uniqueCode);

  String get expiryAt => _text(raw['expiryAt'] ?? raw['expiresAt']);

  bool get isActive {
    final direct = raw['isActive'] ?? raw['active'];
    if (direct is bool) return direct;
    if (direct is num) return direct != 0;
    if (direct is String) {
      final t = direct.trim().toLowerCase();
      return t == 'true' || t == '1' || t == 'active';
    }
    return false;
  }

  bool get isGeofence => _bool(raw['isGeofence'] ?? raw['geofence']);

  bool get isHistory => _bool(raw['isHistory'] ?? raw['history']);

  int get vehiclesCount {
    final direct = _int(raw['vehiclesCount'] ?? raw['vehicleCount']);
    if (direct != null) return direct;
    return vehicles.length;
  }

  int get views =>
      _int(raw['views'] ?? raw['viewCount'] ?? raw['openedCount']) ?? 0;

  String get lastOpenedAt =>
      _text(raw['lastOpenedAt'] ?? raw['last_opened'] ?? raw['lastViewedAt']);

  String get createdAt => _text(raw['createdAt']);

  List<Map<String, dynamic>> get vehicles {
    final value = raw['vehicles'];
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item.cast()))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  String get displayName {
    final explicit = _text(raw['name'] ?? raw['title'] ?? raw['label']);
    if (explicit.isNotEmpty) return explicit;
    if (vehicles.isNotEmpty) {
      final first = vehicles.first;
      final plate = _text(first['plateNumber'] ?? first['plate_number']);
      final name = _text(first['name']);
      if (plate.isNotEmpty) return '$plate Share Link';
      if (name.isNotEmpty) return '$name Share Link';
    }
    if (uniqueCode.isNotEmpty) return 'Share Link $uniqueCode';
    if (id.isNotEmpty) return 'Share Link $id';
    return 'Share Link';
  }

  String get statusLabel {
    final expiry = expiryDate;
    if (expiry != null && expiry.isBefore(DateTime.now())) return 'Expired';
    if (isActive) return 'Active';
    return 'Paused';
  }

  DateTime? get expiryDate {
    final value = expiryAt.trim();
    if (value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  DateTime? get lastOpenedDate {
    final value = lastOpenedAt.trim();
    if (value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  String get vehiclesDisplay {
    if (vehicles.isEmpty) return '';
    final labels = vehicles
        .map(
          (vehicle) => _text(
            vehicle['plateNumber'] ??
                vehicle['plate_number'] ??
                vehicle['name'] ??
                vehicle['title'],
          ),
        )
        .where((value) => value.isNotEmpty)
        .toList();
    return labels.join(' ');
  }

  UserShareTrackLinkItem copyWithRaw(Map<String, dynamic> nextRaw) =>
      UserShareTrackLinkItem(nextRaw);

  static String _text(Object? value) => (value ?? '').toString().trim();

  static int? _int(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString());
  }

  static bool _bool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final t = value.trim().toLowerCase();
      return t == 'true' || t == '1' || t == 'yes';
    }
    return false;
  }
}
