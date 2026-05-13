class AdminLinkedVehicle {
  final int id;
  final String name;
  final String plateNumber;
  final String? secondaryExpiry;
  final String? imei;
  final AdminVehiclePlan? plan;

  const AdminLinkedVehicle({
    required this.id,
    required this.name,
    required this.plateNumber,
    this.secondaryExpiry,
    this.imei,
    this.plan,
  });

  factory AdminLinkedVehicle.fromJson(Map<String, Object?> json) {
    final device = json['device'];
    final deviceMap = device is Map ? Map<String, Object?>.from(device.cast()) : const <String, Object?>{};
    final plan = json['plan'];
    final planMap = plan is Map ? Map<String, Object?>.from(plan.cast()) : null;
    return AdminLinkedVehicle(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      plateNumber: (json['plateNumber'] ?? '').toString(),
      secondaryExpiry: json['secondaryExpiry']?.toString(),
      imei: deviceMap['imei']?.toString(),
      plan: planMap == null ? null : AdminVehiclePlan.fromJson(planMap),
    );
  }
}

class AdminVehiclePlan {
  final int id;
  final String name;
  final double price;
  final int durationDays;
  final String currency;

  const AdminVehiclePlan({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.currency,
  });

  factory AdminVehiclePlan.fromJson(Map<String, Object?> json) {
    return AdminVehiclePlan(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      price: _toDouble(json['price']),
      durationDays: _toInt(json['durationDays']),
      currency: (json['currency'] ?? 'INR').toString(),
    );
  }
}

int _toInt(Object? value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

double _toDouble(Object? value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0.0;
