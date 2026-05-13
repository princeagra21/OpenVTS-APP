class CreateUserVehicleInput {
  const CreateUserVehicleInput({
    required this.imei,
    required this.plateNumber,
    required this.vehicleTypeId,
    required this.gmtOffset,
    this.vin,
  });

  final String imei;
  final String plateNumber;
  final String vehicleTypeId;
  final String gmtOffset;
  final String? vin;

  Map<String, Object?> toPayload() => <String, Object?>{
        'name': plateNumber.trim(),
        'plateNumber': plateNumber.trim(),
        'imei': imei.trim(),
        'vehicleTypeId': int.tryParse(vehicleTypeId.trim()) ?? vehicleTypeId.trim(),
        'gmtOffset': gmtOffset.trim(),
        if ((vin ?? '').trim().isNotEmpty) 'vin': vin!.trim(),
      };
}
