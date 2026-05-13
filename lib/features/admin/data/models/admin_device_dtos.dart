class AdminDeviceDto {
  const AdminDeviceDto(this.json);

  final Map<String, Object?> json;

  factory AdminDeviceDto.fromJson(Map<String, Object?> json) {
    return AdminDeviceDto(Map<String, Object?>.unmodifiable(json));
  }
}

class CreateAdminDeviceRequestDto {
  const CreateAdminDeviceRequestDto({
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

  Map<String, Object?> toJson() {
    final body = <String, Object?>{
      'imei': imei.trim(),
      'deviceTypeId': _toNumOrString(deviceTypeId.trim()),
    };
    final sim = (simId ?? '').trim();
    if (sim.isNotEmpty) body['simId'] = _toNumOrString(sim);
    final simNo = (simNumber ?? '').trim();
    if (simNo.isNotEmpty) body['simNumber'] = simNo;
    final provider = (providerId ?? '').trim();
    if (provider.isNotEmpty) body['providerId'] = _toNumOrString(provider);
    final imsiValue = (imsi ?? '').trim();
    if (imsiValue.isNotEmpty) body['imsi'] = imsiValue;
    final iccidValue = (iccid ?? '').trim();
    if (iccidValue.isNotEmpty) body['iccid'] = iccidValue;
    return body;
  }
}

class CreateAdminDeviceAndSimRequestDto {
  const CreateAdminDeviceAndSimRequestDto({
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

  Map<String, Object?> toJson() {
    final body = <String, Object?>{
      'imei': imei.trim(),
      'deviceTypeId': _toNumOrString(deviceTypeId.trim()),
      'simNumber': simNumber.trim(),
    };
    final provider = (providerId ?? '').trim();
    if (provider.isNotEmpty) body['providerId'] = _toNumOrString(provider);
    final imsiValue = (imsi ?? '').trim();
    if (imsiValue.isNotEmpty) body['imsi'] = imsiValue;
    final iccidValue = (iccid ?? '').trim();
    if (iccidValue.isNotEmpty) body['iccid'] = iccidValue;
    return body;
  }
}

class UpdateAdminDeviceRequestDto {
  const UpdateAdminDeviceRequestDto({
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

  Map<String, Object?> toJson() {
    final body = <String, Object?>{...extra};
    void addText(String key, String? value) {
      final text = (value ?? '').trim();
      if (text.isNotEmpty) body[key] = text;
    }
    if ((imei ?? '').trim().isNotEmpty) addText('imei', imei);
    if ((deviceTypeId ?? '').trim().isNotEmpty) {
      body['deviceTypeId'] = _toNumOrString(deviceTypeId!.trim());
    }
    if (clearSim) {
      body['simId'] = null;
    } else if ((simId ?? '').trim().isNotEmpty) {
      body['simId'] = _toNumOrString(simId!.trim());
    }
    addText('simNumber', simNumber);
    if ((providerId ?? '').trim().isNotEmpty) body['providerId'] = _toNumOrString(providerId!.trim());
    addText('imsi', imsi);
    addText('iccid', iccid);
    if (isActive != null) body['isActive'] = isActive;
    addText('status', status);
    return body;
  }
}

Object _toNumOrString(String value) {
  final parsed = int.tryParse(value);
  return parsed ?? value;
}


class CreateAdminSimCardRequestDto {
  const CreateAdminSimCardRequestDto({
    required this.simNumber,
    this.providerId,
    this.imsi,
    this.iccid,
  });

  final String simNumber;
  final String? providerId;
  final String? imsi;
  final String? iccid;

  Map<String, Object?> toJson() {
    final body = <String, Object?>{'simNumber': simNumber.trim()};
    final provider = (providerId ?? '').trim();
    if (provider.isNotEmpty) body['providerId'] = _toNumOrString(provider);
    final imsiValue = (imsi ?? '').trim();
    if (imsiValue.isNotEmpty) body['imsi'] = imsiValue;
    final iccidValue = (iccid ?? '').trim();
    if (iccidValue.isNotEmpty) body['iccid'] = iccidValue;
    return body;
  }
}
