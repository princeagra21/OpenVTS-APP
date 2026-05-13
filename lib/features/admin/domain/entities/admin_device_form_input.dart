class CreateAdminDeviceInput {
  const CreateAdminDeviceInput({
    required this.imei,
    required this.deviceTypeId,
    this.simId,
  });

  final String imei;
  final String deviceTypeId;
  final String? simId;
}
