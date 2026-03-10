class AdminVehiclePreviewItem {
  final Map<String, dynamic> raw;
  final String? liveStatusOverride;

  const AdminVehiclePreviewItem(this.raw, {this.liveStatusOverride});

  String get id {
    return _str(
      raw['id'] ?? raw['vehicleId'] ?? raw['uid'] ?? raw['_id'] ?? raw['value'],
    );
  }

  String get imei {
    return _str(raw['imei'] ?? raw['deviceImei'] ?? raw['imeiNumber']);
  }

  String get plateNumber {
    final plate = _str(
      raw['plateNumber'] ?? raw['plate'] ?? raw['registrationNo'],
    );
    if (plate.isNotEmpty) return plate;
    final name = _str(raw['name'] ?? raw['title'] ?? raw['vehicleName']);
    if (name.isNotEmpty) return name;
    final fallback = id;
    return fallback.isNotEmpty ? fallback : '—';
  }

  String get statusLabel {
    final source =
        liveStatusOverride ??
        raw['liveStatus'] ??
        raw['status'] ??
        raw['vehicleStatus'] ??
        raw['motion'] ??
        raw['state'] ??
        raw['ignition'] ??
        '';
    return normalizeStatusLabel(_str(source));
  }

  String get lastSeenRaw {
    return _str(
      raw['lastSeen'] ??
          raw['updatedAt'] ??
          raw['lastPing'] ??
          raw['timestamp'] ??
          raw['gpsTime'] ??
          raw['time'],
    );
  }

  String get lastSeenLabel {
    final value = lastSeenRaw;
    if (value.isEmpty) return '—';

    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;

    final diff = DateTime.now().toUtc().difference(parsed.toUtc());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 30) return '${diff.inDays} d ago';
    return value.split('T').first;
  }

  AdminVehiclePreviewItem withLiveStatus(String? status) {
    if (status == null || status.trim().isEmpty) return this;
    return AdminVehiclePreviewItem(raw, liveStatusOverride: status);
  }

  static String normalizeStatusLabel(String raw) {
    final input = raw.trim();
    if (input.isEmpty) return '—';

    final lower = input.toLowerCase();
    if (lower.contains('running') || lower.contains('moving')) return 'Running';
    if (lower == 'active' || lower.contains('online')) return 'Active';
    if (lower.contains('idle')) return 'Idle';
    if (lower.contains('stop') ||
        lower.contains('stopped') ||
        lower.contains('park')) {
      return 'Stop';
    }
    if (lower.contains('no data') || lower.contains('nodata')) {
      return 'Inactive';
    }
    if (lower.contains('inactive') ||
        lower.contains('offline') ||
        lower.contains('disconnect')) {
      return 'Inactive';
    }

    return input;
  }

  static String _str(Object? value) {
    if (value == null) return '';
    return value.toString().trim();
  }
}
