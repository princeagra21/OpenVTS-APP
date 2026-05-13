class CreateAdminDeviceMutationInput {
  const CreateAdminDeviceMutationInput({
    required this.imei,
    required this.deviceTypeId,
    this.simId,
    this.simNumber,
    this.providerId,
    this.imsi,
    this.iccid,
  });

  final String imei;
  final String deviceTypeId;
  final String? simId;
  final String? simNumber;
  final String? providerId;
  final String? imsi;
  final String? iccid;
}

class CreateAdminDeviceAndSimMutationInput {
  const CreateAdminDeviceAndSimMutationInput({
    required this.imei,
    required this.deviceTypeId,
    required this.simNumber,
    this.providerId,
    this.imsi,
    this.iccid,
  });

  final String imei;
  final String deviceTypeId;
  final String simNumber;
  final String? providerId;
  final String? imsi;
  final String? iccid;
}

class UpdateAdminDeviceMutationInput {
  const UpdateAdminDeviceMutationInput({
    this.imei,
    this.deviceTypeId,
    this.simId,
    this.simNumber,
    this.providerId,
    this.imsi,
    this.iccid,
    this.isActive,
    this.status,
    this.clearSim = false,
    this.extra = const <String, Object?>{},
  });

  final String? imei;
  final String? deviceTypeId;
  final String? simId;
  final String? simNumber;
  final String? providerId;
  final String? imsi;
  final String? iccid;
  final bool? isActive;
  final String? status;
  final bool clearSim;
  final Map<String, Object?> extra;
}


class CreateAdminSimCardMutationInput {
  const CreateAdminSimCardMutationInput({
    required this.simNumber,
    this.providerId,
    this.imsi,
    this.iccid,
  });

  final String simNumber;
  final String? providerId;
  final String? imsi;
  final String? iccid;
}
