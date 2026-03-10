class SimProviderOption {
  final Map<String, dynamic> raw;

  const SimProviderOption(this.raw);

  factory SimProviderOption.fromRaw(Map<String, dynamic> raw) {
    return SimProviderOption(raw);
  }

  String get id {
    final value = raw['id'] ?? raw['providerId'] ?? raw['uid'] ?? raw['_id'];
    if (value == null) return '';
    return value.toString().trim();
  }

  String get name {
    final value = raw['name'] ?? raw['provider'] ?? raw['label'];
    if (value == null) return '';
    final out = value.toString().trim();
    if (out.toLowerCase() == 'null') return '';
    return out;
  }
}
