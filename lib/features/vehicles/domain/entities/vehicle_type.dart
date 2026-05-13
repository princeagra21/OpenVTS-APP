class VehicleType {
  final int id;
  final String name;

  const VehicleType({required this.id, required this.name});

  factory VehicleType.fromRaw(Map<String, Object?> json) {
    final rawId = json['id'];
    return VehicleType(
      id: rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}
