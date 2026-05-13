class Vehicle {
  const Vehicle({
    required this.id,
    required this.name,
    this.plateNumber = '',
    this.imei = '',
    this.status = '',
    this.raw = const <String, dynamic>{},
  });

  final String id;
  final String name;
  final String plateNumber;
  final String imei;
  final String status;
  final Map<String, Object?> raw;
}
