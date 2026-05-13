class AdminQuickDevice {
  final int id;
  final String imei;

  const AdminQuickDevice({required this.id, required this.imei});

  factory AdminQuickDevice.fromRaw(Map<String, Object?> json) {
    final rawId = json['id'];
    return AdminQuickDevice(
      id: rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0,
      imei: json['imei']?.toString() ?? '',
    );
  }
}
