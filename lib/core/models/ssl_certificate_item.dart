class SslCertificateItem {
  final Map<String, dynamic> raw;

  const SslCertificateItem(this.raw);

  String get id => _string(
    raw['id'] ??
        raw['certificateId'] ??
        raw['certId'] ??
        raw['domainId'] ??
        raw['uuid'],
  );

  String get domain => _string(
    raw['domain'] ??
        raw['host'] ??
        raw['hostname'] ??
        raw['url'] ??
        raw['customDomain'],
  );

  String get status =>
      _string(raw['status'] ?? raw['state'] ?? raw['sslStatus']);

  String get issuer => _string(raw['issuer'] ?? raw['certificateIssuer']);

  String get validFrom =>
      _string(raw['validFrom'] ?? raw['issuedAt'] ?? raw['notBefore']);

  String get validTo =>
      _string(raw['validTo'] ?? raw['expiresAt'] ?? raw['notAfter']);

  int? get daysRemaining {
    final value = raw['daysRemaining'] ?? raw['remainingDays'];
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }

  String get error => _string(raw['error'] ?? raw['message'] ?? raw['details']);

  String get companyName =>
      _string(raw['companyName'] ?? raw['company'] ?? raw['organization']);

  String get expiryText => _string(
    raw['expiry'] ??
        raw['expiresAt'] ??
        raw['expirationDate'] ??
        raw['validTill'] ??
        raw['validTo'],
  );

  DateTime? get expiryDate {
    final rawValue =
        raw['expiry'] ??
        raw['expiresAt'] ??
        raw['expirationDate'] ??
        raw['validTill'] ??
        raw['validTo'] ??
        raw['notAfter'];
    if (rawValue == null) return null;
    if (rawValue is DateTime) return rawValue;

    final text = rawValue.toString().trim();
    if (text.isEmpty) return null;

    final iso = DateTime.tryParse(text);
    if (iso != null) return iso;

    // Tolerate UI-like dates such as "12 Jan 2026" / "15 Sept 2025".
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ');
    final m = RegExp(
      r'^(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (m == null) return null;

    final day = int.tryParse(m.group(1) ?? '');
    final monthToken = (m.group(2) ?? '').toLowerCase();
    final year = int.tryParse(m.group(3) ?? '');
    if (day == null || year == null) return null;

    const monthMap = <String, int>{
      'jan': 1,
      'january': 1,
      'feb': 2,
      'february': 2,
      'mar': 3,
      'march': 3,
      'apr': 4,
      'april': 4,
      'may': 5,
      'jun': 6,
      'june': 6,
      'jul': 7,
      'july': 7,
      'aug': 8,
      'august': 8,
      'sep': 9,
      'sept': 9,
      'september': 9,
      'oct': 10,
      'october': 10,
      'nov': 11,
      'november': 11,
      'dec': 12,
      'december': 12,
    };

    final month = monthMap[monthToken];
    if (month == null) return null;

    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  static List<SslCertificateItem> fromResponse(Object? data) {
    final list = _extractList(data);
    if (list == null) return const <SslCertificateItem>[];

    final out = <SslCertificateItem>[];
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        out.add(SslCertificateItem(item));
      } else if (item is Map) {
        out.add(SslCertificateItem(Map<String, dynamic>.from(item.cast())));
      }
    }
    return out;
  }

  static List? _extractList(Object? data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final candidates = <Object?>[
        data['data'],
        data['items'],
        data['result'],
        data['results'],
        data['certificates'],
        data['domains'],
        data['domainlist'],
      ];
      for (final c in candidates) {
        if (c is List) return c;
        if (c is Map<String, dynamic>) {
          final nested = _extractList(c);
          if (nested != null) return nested;
        } else if (c is Map) {
          final nested = _extractList(Map<String, dynamic>.from(c.cast()));
          if (nested != null) return nested;
        }
      }
    }
    if (data is Map) {
      return _extractList(Map<String, dynamic>.from(data.cast()));
    }
    return null;
  }

  static String _string(Object? value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }
}
