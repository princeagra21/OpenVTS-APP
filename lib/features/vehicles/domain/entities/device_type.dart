class DeviceType {
  final int id;
  final String name;
  final int port;

  const DeviceType({required this.id, required this.name, required this.port});

  factory DeviceType.fromRaw(Map<String, Object?> json) {
    final rawId = json['id'];
    final rawPort = json['port'];
    return DeviceType(
      id: rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      port: rawPort is int ? rawPort : int.tryParse(rawPort?.toString() ?? '') ?? 0,
    );
  }
}
