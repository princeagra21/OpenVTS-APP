class AdminTransactionsSummary {
  final Map<String, dynamic> raw;

  const AdminTransactionsSummary(this.raw);

  factory AdminTransactionsSummary.fromRaw(Map<String, dynamic> raw) {
    return AdminTransactionsSummary(raw);
  }

  int? get availableCredits => _firstInt(const [
    'availableCredits',
    'creditsBalance',
    'balanceCredits',
    'walletCredits',
    'available_credits',
  ]);

  double? get processed30DaysAmount => _firstDouble(const [
    'processed30DaysAmount',
    'processedAmount30d',
    'totalProcessed30d',
    'totalAmount30d',
    'processedAmount',
    'monthlyProcessed',
  ]);

  int? get processed30DaysCount => _firstInt(const [
    'processed30DaysCount',
    'totalTransactions',
    'count30d',
    'processedCount',
  ]);

  String get currency {
    final value = _firstString(const ['currency', 'currencyCode']);
    if (value.isNotEmpty) return value;

    final totals = raw['totalsByCurrency'];
    if (totals is List && totals.isNotEmpty && totals.first is Map) {
      final map = Map<String, dynamic>.from((totals.first as Map).cast());
      final c = map['currency'] ?? map['currencyCode'];
      if (c != null) {
        final out = c.toString().trim();
        if (out.isNotEmpty && out.toLowerCase() != 'null') return out;
      }
    }

    return 'INR';
  }

  double? get amountFromTotalsByCurrency {
    final totals = raw['totalsByCurrency'];
    if (totals is! List || totals.isEmpty) return null;

    var sum = 0.0;
    var found = false;

    for (final item in totals) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item.cast());
      final val = map['amount'] ?? map['totalAmount'] ?? map['value'];
      if (val is num) {
        found = true;
        sum += val.toDouble();
      } else if (val != null) {
        final parsed = double.tryParse(val.toString().trim());
        if (parsed != null) {
          found = true;
          sum += parsed;
        }
      }
    }

    return found ? sum : null;
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
