class SimOption {
  final Map<String, dynamic> raw;

  const SimOption(this.raw);

  factory SimOption.fromRaw(Map<String, dynamic> raw) {
    return SimOption(raw);
  }

  String get id {
    final value = raw['id'] ?? raw['simId'] ?? raw['uid'] ?? raw['_id'];
    if (value == null) return '';
    return value.toString().trim();
  }

  String get number {
    final value = raw['simNumber'] ?? raw['number'] ?? raw['simNo'];
    if (value == null) return '';
    final out = value.toString().trim();
    if (out.toLowerCase() == 'null') return '';
    return out;
  }

  String get provider {
    final provider = raw['provider'];
    if (provider is Map) {
      final nested = provider['name'] ?? provider['providerName'];
      if (nested != null) {
        final out = nested.toString().trim();
        if (out.isNotEmpty && out.toLowerCase() != 'null') return out;
      }
    }

    final direct = raw['providerName'] ?? raw['provider'];
    if (direct == null) return '';
    final out = direct.toString().trim();
    if (out.toLowerCase() == 'null') return '';
    return out;
  }

  String get label {
    final n = number;
    final p = provider;
    if (n.isEmpty && p.isEmpty) return '';
    if (p.isEmpty) return n;
    if (n.isEmpty) return p;
    return '$n • $p';
  }
}
