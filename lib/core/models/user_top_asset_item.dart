class UserTopAssetItem {
  final Map<String, dynamic> raw;

  const UserTopAssetItem(this.raw);

  String get id => _string(
    raw['id'] ??
        raw['_id'] ??
        raw['vehicleId'] ??
        raw['assetId'] ??
        raw['imei'],
  );

  String get title =>
      _nonEmpty([
        raw['name'],
        raw['vehicleName'],
        raw['assetName'],
        raw['plateNumber'],
        raw['vehicleNo'],
        raw['registrationNumber'],
        raw['imei'],
      ]) ??
      'Asset';

  String get subtitle =>
      _nonEmpty([
        raw['plateNumber'],
        raw['vehicleNo'],
        raw['registrationNumber'],
        raw['imei'],
        raw['type'],
        raw['status'],
      ]) ??
      '—';

  String get metricLabel {
    final distance = _double(
      raw['drivenKm'] ?? raw['distanceKm'] ?? raw['distance'],
    );
    if (distance != null) return '${_formatNumber(distance)} km';

    final hours = _double(raw['engineHours'] ?? raw['hours']);
    if (hours != null) return '${_formatNumber(hours)} h';

    final trips = _int(raw['trips'] ?? raw['tripCount']);
    if (trips != null) return '$trips trips';

    final score = _double(raw['score'] ?? raw['performanceScore']);
    if (score != null) return 'Score ${_formatNumber(score)}';

    final status = _string(raw['status']);
    if (status.isNotEmpty) return status;

    return '—';
  }

  static String _string(Object? value) => (value ?? '').toString().trim();

  static String? _nonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = _string(value);
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static double? _double(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(_string(value).replaceAll(',', ''));
  }

  static int? _int(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(_string(value).replaceAll(',', ''));
  }

  static String _formatNumber(double value) {
    final rounded = value.roundToDouble();
    if (rounded == value) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}
