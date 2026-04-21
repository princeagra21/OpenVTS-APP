class AdminQuickDevice {
  final int id;
  final String imei;

  const AdminQuickDevice({required this.id, required this.imei});

  factory AdminQuickDevice.fromRaw(Map<String, dynamic> json) {
    return AdminQuickDevice(
      id: json['id'] ?? 0,
      imei: json['imei']?.toString() ?? '',
    );
  }
}
