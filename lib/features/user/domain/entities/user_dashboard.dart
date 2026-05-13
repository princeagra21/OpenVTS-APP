class UserDashboard {
  const UserDashboard({required this.metrics});

  final Map<String, Object?> metrics;

  int get totalVehicles => _int(metrics['totalVehicles'] ?? metrics['vehiclesCount']);
  int get activeAlerts => _int(metrics['activeAlerts'] ?? metrics['alertsCount']);

  static int _int(Object? value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value.replaceAll(',', '').trim()) ?? 0;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
