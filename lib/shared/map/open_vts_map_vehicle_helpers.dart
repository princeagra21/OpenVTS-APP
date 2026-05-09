part of 'open_vts_map_screen.dart';

extension _OpenVtsMapVehicleHelpers on _OpenVtsMapScreenState {
  bool _matchesVehicleSearch(MapVehiclePoint point, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return _vehicleSearchText(point).contains(q);
  }

  String _vehicleSearchText(MapVehiclePoint point) {
    final raw = point.raw;
    final values = <String>[
      _vehicleTitle(point),
      _vehicleDisplayName(point),
      point.plateNumber,
      point.imei,
      _rawText(raw, const [
        'deviceImei',
        'device_imei',
        'deviceImeiNumber',
        'device_imei_number',
        'imeiNumber',
      ]),
      point.vehicleTypeName,
      point.status,
      normalizeMapVehicleStatus(point).label,
      _vehicleAddressText(point),
    ];
    return values
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .join(' ');
  }

  String _vehicleDisplayName(MapVehiclePoint point) {
    final raw = point.raw;
    final candidates = <String>[
      _rawText(raw, const [
        'vehicleName',
        'vehicle_name',
        'name',
        'title',
        'displayName',
        'display_name',
        'vehicleTitle',
        'vehicle_title',
      ]),
      point.plateNumber,
    ];
    for (final candidate in candidates) {
      final value = candidate.trim();
      if (value.isNotEmpty) return value;
    }
    return _vehicleTitle(point);
  }

  String _rawText(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  bool _isValidVehicleLocation(MapVehiclePoint vehicle) {
    return vehicle.hasValidPoint &&
        vehicle.lat.isFinite &&
        vehicle.lng.isFinite &&
        !(vehicle.lat == 0 && vehicle.lng == 0);
  }

  String _getStatusTitle(MapVehicleStatusFilter filter) => filter.label;

  Color _getStatusColor(MapVehicleStatusFilter filter) {
    switch (filter) {
      case MapVehicleStatusFilter.running:
        return Colors.green;
      case MapVehicleStatusFilter.stop:
        return Colors.redAccent;
      case MapVehicleStatusFilter.idle:
        return Colors.orange;
      case MapVehicleStatusFilter.inactive:
        return Colors.grey;
      case MapVehicleStatusFilter.noData:
        return Colors.black87;
      case MapVehicleStatusFilter.all:
        return Colors.black;
    }
  }

  String _vehicleAddressText(MapVehiclePoint point) {
    final raw = point.raw;
    final values = <Object?>[
      raw['fullAddress'],
      raw['address'],
      raw['addressLine'],
      raw['location'],
    ];
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  String _formatLastSeen(MapVehiclePoint point) {
    return _formatVehicleListLastUpdate(point);
  }

  String _formatSpeed(MapVehiclePoint point) {
    return _formatVehicleListSpeed(point);
  }

  double? _vehicleSpeedKph(MapVehiclePoint vehicle) {
    final raw = vehicle.raw;
    final candidates = <Object?>[
      raw['speedKph'],
      raw['speed_kph'],
      raw['speed'],
      raw['currentSpeed'],
      raw['telemetry'] is Map ? (raw['telemetry'] as Map)['speedKph'] : null,
      raw['telemetry'] is Map ? (raw['telemetry'] as Map)['speed_kph'] : null,
      raw['telemetry'] is Map ? (raw['telemetry'] as Map)['speed'] : null,
      raw['telemetry'] is Map
          ? (raw['telemetry'] as Map)['currentSpeed']
          : null,
      raw['latestTelemetry'] is Map
          ? (raw['latestTelemetry'] as Map)['speedKph']
          : null,
      raw['latestTelemetry'] is Map
          ? (raw['latestTelemetry'] as Map)['speed_kph']
          : null,
      raw['latestTelemetry'] is Map
          ? (raw['latestTelemetry'] as Map)['speed']
          : null,
      raw['latestTelemetry'] is Map
          ? (raw['latestTelemetry'] as Map)['currentSpeed']
          : null,
    ];
    for (final candidate in candidates) {
      final parsed = candidate == null
          ? null
          : (candidate is num
                ? candidate.toDouble()
                : double.tryParse(candidate.toString()));
      if (parsed != null) return parsed;
    }
    return vehicle.speedKph ?? vehicle.speed;
  }

  DateTime? _vehicleLastUpdateDateTime(MapVehiclePoint vehicle) {
    final raw = vehicle.raw;
    final candidates = <Object?>[
      raw['serverTime'],
      raw['server_time'],
      raw['deviceTime'],
      raw['device_time'],
      raw['lastUpdate'],
      raw['last_update'],
      raw['updatedAt'],
      raw['updated_at'],
      raw['lastSeen'],
      raw['lastSeenAt'],
      raw['last_seen_at'],
      raw['timestamp'],
      raw['time'],
      vehicle.updatedAt,
      vehicle.serverTime,
      vehicle.deviceTime,
      raw['telemetry'] is Map ? (raw['telemetry'] as Map)['serverTime'] : null,
      raw['telemetry'] is Map ? (raw['telemetry'] as Map)['server_time'] : null,
      raw['telemetry'] is Map ? (raw['telemetry'] as Map)['deviceTime'] : null,
      raw['telemetry'] is Map ? (raw['telemetry'] as Map)['device_time'] : null,
      raw['latestTelemetry'] is Map
          ? (raw['latestTelemetry'] as Map)['serverTime']
          : null,
      raw['latestTelemetry'] is Map
          ? (raw['latestTelemetry'] as Map)['server_time']
          : null,
      raw['latestTelemetry'] is Map
          ? (raw['latestTelemetry'] as Map)['deviceTime']
          : null,
      raw['latestTelemetry'] is Map
          ? (raw['latestTelemetry'] as Map)['device_time']
          : null,
    ];

    for (final candidate in candidates) {
      final dt = candidate == null
          ? null
          : (candidate is DateTime
                ? candidate
                : candidate is num
                ? DateTime.fromMillisecondsSinceEpoch(
                    candidate > 1000000000000
                        ? candidate.toInt()
                        : candidate.toInt() * 1000,
                  )
                : DateTime.tryParse(candidate.toString().trim()));
      if (dt != null) return dt;
    }
    return null;
  }

  String _formatVehicleListSpeed(MapVehiclePoint vehicle) {
    final speed = _vehicleSpeedKph(vehicle);
    if (speed == null) return '0 km/h';
    return '${speed.round()} km/h';
  }

  String _formatVehicleListLastUpdate(MapVehiclePoint vehicle) {
    final dt = _vehicleLastUpdateDateTime(vehicle);
    if (dt == null) return 'Unknown';

    final local = dt.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day.toString().padLeft(2, '0')} ${months[local.month - 1]} '
        '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  String? _formatDistance(MapVehiclePoint point) {
    final raw = point.raw;
    final distance = raw['distance'] ?? raw['distanceKm'] ?? raw['drivenKm'];
    if (distance == null) return null;
    final parsed = double.tryParse(distance.toString());
    if (parsed == null) return distance.toString();
    final formatted = parsed % 1 == 0
        ? parsed.toStringAsFixed(0)
        : parsed.toStringAsFixed(1);
    return '$formatted km';
  }

  String _vehicleTitle(MapVehiclePoint point) {
    final title = point.plateNumber.trim();
    if (title.isNotEmpty) return title;
    final imei = point.imei.trim();
    if (imei.isNotEmpty) return imei;
    final id = point.vehicleId.trim();
    if (id.isNotEmpty) return id;
    return 'Vehicle';
  }

  bool _shouldAnimateRipple(MapVehicleStatusFilter status, bool isSelected) {
    if (isSelected) return true;
    return status == MapVehicleStatusFilter.running;
  }

  Color _vehicleMarkerColor(MapVehiclePoint point, {required bool isSelected}) {
    // We use status-specific colors even if selected for the dot/ripple,
    // but the main theme might use a dark color for selection emphasis.
    switch (normalizeMapVehicleStatus(point)) {
      case MapVehicleStatusFilter.running:
        return const Color(0xFF22C55E); // green
      case MapVehicleStatusFilter.stop:
        return const Color(0xFFEF4444); // red
      case MapVehicleStatusFilter.idle:
        return const Color(0xFFF59E0B); // amber/orange
      case MapVehicleStatusFilter.inactive:
        return const Color(0xFF6B7280); // gray
      case MapVehicleStatusFilter.noData:
        return const Color(0xFF374151); // dark gray
      case MapVehicleStatusFilter.all:
        return const Color(0xFF22C55E);
    }
  }

  String _vehicleBaseTypeSlug(MapVehiclePoint point) {
    final type = point.vehicleTypeName.toLowerCase().trim();
    if (type.contains('sedan') || type.contains('saloon')) return 'sedan_car';
    if (type.contains('suv') || type.contains('jeep')) return 'suv_car';
    if (type.contains('pickup') ||
        type.contains('fullback') ||
        type.contains('hilux') ||
        type.contains('double cab') ||
        type.contains('ute')) {
      return 'pickup_truck';
    }
    if (type.contains('tank')) return 'tanker_truck';
    if (type.contains('box')) return 'box_truck';
    if (type.contains('cargo') || type.contains('van')) return 'cargo_van';
    if (type.contains('car')) return 'sedan_car';
    if (type.contains('truck') ||
        type.contains('lorry') ||
        type.contains('lorri')) {
      return 'pickup_truck';
    }
    return 'pickup_truck';
  }

  String _normalizedStatusKey(MapVehicleStatusFilter status) {
    switch (status) {
      case MapVehicleStatusFilter.running:
        return 'running';
      case MapVehicleStatusFilter.stop:
        return 'stop';
      case MapVehicleStatusFilter.idle:
        return 'idle';
      case MapVehicleStatusFilter.inactive:
        return 'inactive';
      case MapVehicleStatusFilter.noData:
        return 'nodata';
      case MapVehicleStatusFilter.all:
        return 'nodata';
    }
  }

  String _vehicleMarkerAssetPath(
    MapVehiclePoint point,
    MapVehicleStatusFilter status,
  ) {
    final typeSlug = _vehicleBaseTypeSlug(point);
    final statusKey = _normalizedStatusKey(status);
    return 'assets/images/vehicleicons/$typeSlug$statusKey.png';
  }

  String _vehicleBaseAssetPath(MapVehiclePoint point) {
    final typeSlug = _vehicleBaseTypeSlug(point);
    return 'assets/images/vehicleicons/${typeSlug}White.png';
  }
}
