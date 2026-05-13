class AdminDashboard {
  const AdminDashboard({required this.metrics});

  final Map<String, Object?> metrics;

  int get totalVehicles => _int(metrics['totalVehicles'] ?? metrics['vehiclesCount'] ?? metrics['vehicleCount']);
  int get totalUsers => _int(metrics['totalUsers'] ?? metrics['usersCount'] ?? metrics['userCount']);
  int get runningVehicles => _int(metrics['running'] ?? metrics['runningVehicles']);
  int get stoppedVehicles => _int(metrics['stopped'] ?? metrics['stop'] ?? metrics['stoppedVehicles']);

  static int _int(Object? value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value.replaceAll(',', '').trim()) ?? 0;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
