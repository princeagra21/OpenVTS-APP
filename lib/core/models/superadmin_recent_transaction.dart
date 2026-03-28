class SuperadminRecentTransaction {
  final Map<String, dynamic> raw;

  const SuperadminRecentTransaction(this.raw);

  String get id => _string(
    raw['id'] ??
        raw['transactionId'] ??
        raw['transaction_id'] ??
        raw['reference'] ??
        raw['ref'] ??
        raw['code'],
  );

  String get status => _string(raw['status'] ?? raw['state'] ?? raw['type']);

  String get amount => _string(
    raw['amount'] ??
        raw['value'] ??
        raw['total'] ??
        raw['credit'] ??
        raw['debit'],
  );

  String get currency => _string(raw['currency'] ?? raw['currencyCode']);

  String get actorName => _string(
    raw['name'] ??
        raw['userName'] ??
        raw['adminName'] ??
        (raw['user'] is Map ? (raw['user'] as Map)['name'] : null),
  );

  String get fromUserName {
    final from = raw['fromUser'];
    if (from is Map) {
      return _string(from['name'] ?? from['username'] ?? from['email']);
    }
    return '';
  }

  String get fromUserId {
    return _string(
      raw['fromUserId'] ??
          raw['from_user_id'] ??
          (raw['fromUser'] is Map ? (raw['fromUser'] as Map)['uid'] : null),
    );
  }

  String get fromUserEmail {
    final from = raw['fromUser'];
    if (from is Map) {
      return _string(from['email']);
    }
    return '';
  }

  String get description => _string(
    raw['description'] ??
        raw['notes'] ??
        raw['activity'] ??
        raw['title'] ??
        raw['remark'],
  );

  String get time => _string(
    raw['time'] ??
        raw['createdAt'] ??
        raw['created_at'] ??
        raw['updatedAt'] ??
        raw['updated_at'],
  );

  String get valueText {
    final amountValue = amount;
    if (amountValue.isEmpty) return '';
    if (currency.isEmpty) return amountValue;
    return '$currency $amountValue';
  }

  static String _string(Object? value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }
}
