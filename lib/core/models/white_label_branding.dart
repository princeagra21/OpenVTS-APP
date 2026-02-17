class WhiteLabelBranding {
  final Map<String, dynamic> raw;

  const WhiteLabelBranding(this.raw);

  String get baseUrl => _s(
    raw['customDomain'] ??
        raw['domain'] ??
        raw['baseUrl'] ??
        raw['baseURL'] ??
        raw['host'],
  );

  String get serverIp => _s(
    raw['serverIp'] ??
        raw['serverIP'] ??
        raw['ip'] ??
        raw['dnsIp'] ??
        raw['dns_ip'],
  );

  String get faviconUrl =>
      _s(raw['faviconUrl'] ?? raw['favicon'] ?? raw['favIconUrl']);

  String get lightLogoUrl =>
      _s(raw['logoLightUrl'] ?? raw['lightLogoUrl'] ?? raw['logoLight']);

  String get darkLogoUrl =>
      _s(raw['logoDarkUrl'] ?? raw['darkLogoUrl'] ?? raw['logoDark']);

  String get updatedAt =>
      _s(raw['updatedAt'] ?? raw['updated_at'] ?? raw['modifiedAt']);

  static String _s(Object? v) => v == null ? '' : v.toString();
}
