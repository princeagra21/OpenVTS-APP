class AdminVehicleLogItem {
  const AdminVehicleLogItem({
    required this.id,
    required this.imei,
    required this.packetType,
    required this.deviceTime,
    required this.latitude,
    required this.longitude,
    required this.ignition,
    required this.acc,
    required this.valid,
  });

  final String id;
  final String imei;
  final String packetType;
  final String deviceTime;
  final String latitude;
  final String longitude;
  final String ignition;
  final String acc;
  final String valid;
}
