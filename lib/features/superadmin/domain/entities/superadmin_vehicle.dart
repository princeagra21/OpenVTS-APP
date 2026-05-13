class SuperadminVehicleListItem {
  const SuperadminVehicleListItem({
    required this.id,
    required this.name,
    required this.plateNumber,
    required this.status,
    required this.isActive,
    required this.imei,
    required this.vin,
    required this.simNumber,
    required this.type,
    required this.updatedAt,
    this.raw = const <String, Object?>{},
  });

  final String id;
  final String name;
  final String plateNumber;
  final String status;
  final bool isActive;
  final String imei;
  final String vin;
  final String simNumber;
  final String type;
  final String updatedAt;
  final Map<String, Object?> raw;
}

class SuperadminVehicleDetail {
  const SuperadminVehicleDetail({
    required this.id,
    required this.name,
    required this.plate,
    required this.status,
    required this.isActive,
    required this.imei,
    required this.model,
    required this.type,
    required this.telemetryUpdatedAt,
  });

  final String id;
  final String name;
  final String plate;
  final String status;
  final bool isActive;
  final String imei;
  final String model;
  final String type;
  final String telemetryUpdatedAt;
}

class SuperadminCommandOption {
  const SuperadminCommandOption({
    required this.id,
    required this.name,
    required this.code,
    required this.requiresPayload,
  });

  final String id;
  final String name;
  final String code;
  final bool requiresPayload;
}

class SuperadminSentCommand {
  const SuperadminSentCommand({
    required this.name,
    required this.status,
    required this.createdAt,
  });

  final String name;
  final String status;
  final String createdAt;
}
