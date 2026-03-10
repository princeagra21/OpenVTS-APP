class DeviceTypeOption {
  final Map<String, dynamic> raw;

  const DeviceTypeOption(this.raw);

  factory DeviceTypeOption.fromRaw(Map<String, dynamic> raw) {
    return DeviceTypeOption(raw);
  }

  String get id {
    final value = raw['id'] ?? raw['deviceTypeId'] ?? raw['uid'] ?? raw['_id'];
    if (value == null) return '';
    return value.toString().trim();
  }

  String get name {
    final value = raw['name'] ?? raw['type'] ?? raw['label'];
    if (value == null) return '';
    final out = value.toString().trim();
    if (out.toLowerCase() == 'null') return '';
    return out;
  }
}
