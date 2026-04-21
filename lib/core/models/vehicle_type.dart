class VehicleType {
  final int id;
  final String name;

  const VehicleType({required this.id, required this.name});

  factory VehicleType.fromRaw(Map<String, dynamic> json) {
    return VehicleType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}
