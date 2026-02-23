class WhiteLabelBranding {
  final Map<String, dynamic> raw;

  const WhiteLabelBranding(this.raw);

  Map<String, dynamic> get data {
    final level1 = raw['data'];
    if (level1 is Map) {
      final l1 = Map<String, dynamic>.from(level1.cast());
      final level2 = l1['data'];
      if (level2 is Map) {
        return Map<String, dynamic>.from(level2.cast());
      }
      return l1;
    }
    return raw;
  }

  String get baseUrl => _s(
    data['customDomain'] ??
        data['domain'] ??
        data['baseUrl'] ??
        data['baseURL'] ??
        data['host'],
  );

  String get serverIp {
    final explicit = _s(
      data['serverIp'] ??
          data['serverIP'] ??
          data['ip'] ??
          data['dnsIp'] ??
          data['dns_ip'],
    );
    final fromExplicit = _firstIpv4(explicit);
    if (fromExplicit.isNotEmpty) return fromExplicit;

    final fromDomain = _firstIpv4(baseUrl);
    return fromDomain;
  }

  String get faviconUrl =>
      _s(data['faviconUrl'] ?? data['favicon'] ?? data['favIconUrl']);

  String get lightLogoUrl =>
      _s(data['logoLightUrl'] ?? data['lightLogoUrl'] ?? data['logoLight']);

  String get darkLogoUrl =>
      _s(data['logoDarkUrl'] ?? data['darkLogoUrl'] ?? data['logoDark']);

  String get primaryColor => _s(data['primaryColor'] ?? data['color']);

  String get updatedAt =>
      _s(data['updatedAt'] ?? data['updated_at'] ?? data['modifiedAt']);

  static String _s(Object? v) => v == null ? '' : v.toString();

  static String _firstIpv4(String text) {
    final match = RegExp(
      r'(?<!\d)(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?!\d)',
    ).firstMatch(text);
    return match?.group(0) ?? '';
  }
}
