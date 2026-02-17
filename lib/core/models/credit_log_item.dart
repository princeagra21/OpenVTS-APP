class CreditLogItem {
  final Map<String, dynamic> raw;

  const CreditLogItem(this.raw);

  List<String> get keys => raw.keys.map((k) => k.toString()).toList()..sort();

  String get id => _string(
    raw['id'] ??
        raw['logId'] ??
        raw['log_id'] ??
        raw['creditLogId'] ??
        raw['uuid'] ??
        raw['uid'],
  );

  String get description => _string(
    raw['description'] ??
        raw['title'] ??
        raw['summary'] ??
        raw['message'] ??
        raw['notes'],
  );

  String get type => _string(raw['type'] ?? raw['activity'] ?? raw['action']);

  String get createdAt => _string(
    raw['createdAt'] ?? raw['created_at'] ?? raw['time'] ?? raw['date'],
  );

  int get amount => _int(raw['amount'] ?? raw['credits'] ?? raw['delta']);

  int get balanceAfter => _int(
    raw['balanceAfter'] ??
        raw['balance_after'] ??
        raw['balance'] ??
        raw['currentBalance'],
  );

  bool get isCredit {
    if (amount > 0) return true;
    if (amount < 0) return false;
    final t = type.trim().toUpperCase();
    if (t == 'ASSIGN' || t == 'CREDIT' || t == 'ADD') return true;
    if (t == 'DEDUCT' || t == 'DEBIT' || t == 'REMOVE') return false;
    return true;
  }

  static String _string(Object? v) {
    if (v == null) return '';
    if (v is String) return v;
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
}
