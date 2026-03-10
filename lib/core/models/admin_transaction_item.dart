class AdminTransactionItem {
  final Map<String, dynamic> raw;

  const AdminTransactionItem(this.raw);

  factory AdminTransactionItem.fromRaw(Map<String, dynamic> raw) {
    return AdminTransactionItem(raw);
  }

  String get id =>
      _firstString(const ['id', 'transactionId', 'txId', 'uid', '_id']);

  String get createdAt => _firstString(const [
    'createdAt',
    'date',
    'timestamp',
    'created_at',
    'updatedAt',
  ]);

  String get invoiceNumber {
    final value = _firstString(const [
      'invoiceNumber',
      'invoice',
      'reference',
      'ref',
      'txnNo',
    ]);
    if (value.isNotEmpty) return value;
    if (id.isNotEmpty) return 'Invoice $id';
    return '';
  }

  String get reference => _firstString(const [
    'fsId',
    'fs_id',
    'reference',
    'paymentRef',
    'gatewayRef',
  ]);

  String get description => _firstString(const [
    'description',
    'note',
    'message',
    'purpose',
    'remarks',
  ]);

  String get method => _firstString(const [
    'method',
    'paymentMethod',
    'mode',
    'provider',
    'gateway',
  ]);

  int? get credits =>
      _firstInt(const ['credits', 'credit', 'creditYears', 'creditsDelta']);

  double? get amount =>
      _firstDouble(const ['amount', 'totalAmount', 'value', 'paidAmount']);

  String get currency {
    final value = _firstString(const ['currency', 'currencyCode']);
    if (value.isNotEmpty) return value;
    return 'INR';
  }

  String get rawStatus =>
      _firstString(const ['status', 'paymentStatus', 'state']);

  String get normalizedStatus => normalizeStatus(rawStatus);

  String get statusLabel {
    final n = normalizedStatus;
    if (n == 'success') return 'Success';
    if (n == 'pending') return 'Pending';
    if (n == 'failed') return 'Failed';
    if (n == 'refunded') return 'Refunded';
    final fallback = rawStatus.trim();
    if (fallback.isNotEmpty) return fallback;
    return '—';
  }

  static String normalizeStatus(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    if (value.isEmpty) return '';

    if (value == 'success' ||
        value == 'succeeded' ||
        value == 'paid' ||
        value == 'completed') {
      return 'success';
    }
    if (value == 'pending' || value == 'processing' || value == 'created') {
      return 'pending';
    }
    if (value == 'failed' || value == 'failure' || value == 'declined') {
      return 'failed';
    }
    if (value == 'refunded' || value == 'refund') {
      return 'refunded';
    }

    if (value.contains('success') || value.contains('paid')) return 'success';
    if (value.contains('pend') || value.contains('process')) return 'pending';
    if (value.contains('fail') || value.contains('decline')) return 'failed';
    if (value.contains('refund')) return 'refunded';

    return value;
  }

  String _firstString(List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value == null) continue;
      final out = value.toString().trim();
      if (out.isNotEmpty && out.toLowerCase() != 'null') return out;
    }
    return '';
  }

  int? _firstInt(List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value == null) continue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value.toString().trim());
      if (parsed != null) return parsed;
    }
    return null;
  }

  double? _firstDouble(List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value == null) continue;
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value.toString().trim());
      if (parsed != null) return parsed;
    }
    return null;
  }
}
