class PricingPlan {
  final Map<String, dynamic> raw;

  const PricingPlan(this.raw);

  List<String> get keys => raw.keys.map((k) => k.toString()).toList()..sort();

  String get id => _string(
    raw['id'] ?? raw['planId'] ?? raw['plan_id'] ?? raw['uuid'] ?? raw['uid'],
  );

  String get name => _string(
    raw['name'] ??
        raw['title'] ??
        raw['planName'] ??
        raw['plan_name'] ??
        raw['label'],
  );

  String get status => _string(
    raw['status'] ??
        raw['state'] ??
        raw['isActive'] ??
        raw['active'] ??
        raw['enabled'],
  );

  int get durationDays => _int(raw['durationDays'] ?? raw['duration_days']);

  num get price => _num(raw['price'] ?? raw['amount'] ?? raw['cost']);

  String get currency => _string(raw['currency'] ?? raw['currencyCode']);

  static String _string(Object? v) {
    if (v == null) return '';
    if (v is String) return v;
    if (v is bool) return v ? 'true' : 'false';
    return v.toString();
  }

  static int _int(Object? v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) {
      final cleaned = v.replaceAll(',', '').trim();
      return int.tryParse(cleaned) ?? 0;
    }
    return int.tryParse(v.toString()) ?? 0;
  }

  static num _num(Object? v) {
    if (v == null) return 0;
    if (v is num) return v;
    if (v is String) {
      final cleaned = v.replaceAll(',', '').trim();
      return num.tryParse(cleaned) ?? 0;
    }
    return num.tryParse(v.toString()) ?? 0;
  }
}
