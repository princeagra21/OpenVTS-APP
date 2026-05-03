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

  factory AdminLinkedVehicle.fromJson(Map<String, dynamic> json) {
    final device = json['device'];
    return AdminLinkedVehicle(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] ?? '').toString(),
      plateNumber: (json['plateNumber'] ?? '').toString(),
      secondaryExpiry: json['secondaryExpiry']?.toString(),
      imei: device is Map ? device['imei']?.toString() : null,
      plan: json['plan'] is Map ? AdminVehiclePlan.fromJson(Map<String, dynamic>.from(json['plan'])) : null,
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

  factory AdminVehiclePlan.fromJson(Map<String, dynamic> json) {
    return AdminVehiclePlan(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] ?? '').toString(),
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      durationDays: json['durationDays'] is int ? json['durationDays'] : int.tryParse(json['durationDays']?.toString() ?? '0') ?? 0,
      currency: (json['currency'] ?? 'INR').toString(),
    );
  }
}
