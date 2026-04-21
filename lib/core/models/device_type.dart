class DeviceType {
  final int id;
  final String name;
  final int port;

  const DeviceType({required this.id, required this.name, required this.port});

  factory DeviceType.fromRaw(Map<String, dynamic> json) {
    return DeviceType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      port: json['port'] ?? 0,
    );
  }
}
