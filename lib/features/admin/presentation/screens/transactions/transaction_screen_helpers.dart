part of 'transaction_screen.dart';

extension _TransactionScreenHelpers on _TransactionScreenState {
  double? _computeProcessed30DaysAmount(List<AdminTransactionItem> items) {
    if (items.isEmpty) return 0;

    final now = DateTime.now();
    var sum = 0.0;
    var found = false;

    for (final t in items) {
      if (t.normalizedStatus != 'success') continue;
      final amount = t.amount;
      if (amount == null) continue;

      final date = _tryParseDate(t.createdAt);
      if (date == null) continue;

      final diff = now.difference(date).inDays;
      if (diff >= 0 && diff <= 30) {
        sum += amount;
        found = true;
      }
    }

    return found ? sum : 0;
  }

  List<AdminTransactionItem> _applyLocalFilters(
    List<AdminTransactionItem> source,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    bool tabMatch(AdminTransactionItem item) {
      if (_statusFilter == 'All') return true;
      final expected = AdminTransactionItem.normalizeStatus(_statusFilter);
      final actual = item.normalizedStatus;
      return expected == actual;
    }

    bool queryMatch(AdminTransactionItem item) {
      if (query.isEmpty) return true;

      final fields = [
        item.invoiceNumber,
        item.reference,
        item.description,
        item.method,
        item.statusLabel,
        item.createdAt,
      ];

      return fields.any((v) => v.toLowerCase().contains(query));
    }

    return source.where((item) => tabMatch(item) && queryMatch(item)).toList()
      ..sort((a, b) {
        final db =
            _tryParseDate(b.createdAt) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final da =
            _tryParseDate(a.createdAt) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });
  }

  DateTime? _tryParseDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final parsedIso = DateTime.tryParse(value);
    if (parsedIso != null) return parsedIso;

    final datePart = value.split(',').first.trim();
    final slash = datePart.split(AppRoutePaths.root);
    if (slash.length == 3) {
      final d = int.tryParse(slash[0]);
      final m = int.tryParse(slash[1]);
      final y = int.tryParse(slash[2]);
      if (d != null && m != null && y != null) {
        return DateTime(y, m, d);
      }
    }

    return null;
  }

  String _formatDateTime(String raw) {
    if (raw.trim().isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final m = months[dt.month - 1];
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} $m ${dt.year} · $h:$min';
    } catch (_) {
      return '—';
    }
  }

  String _safe(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '—';
    if (trimmed.toLowerCase() == 'null') return '—';
    return trimmed;
  }

  String _formatCurrency(num value, {String currency = 'INR'}) {
    final symbol = currency.toUpperCase() == 'INR' ? '₹' : '$currency ';
    final sign = value < 0 ? '-' : '';
    final absValue = value.abs();
    final fixed = absValue.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final fracPart = parts[1];
    final withCommas = intPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return '$sign$symbol$withCommas.$fracPart';
  }

  String _formatAmount(double? value, String currency) {
    if (value == null) return '—';
    final symbol = currency.toUpperCase() == 'INR' ? '₹' : '$currency ';
    final isWhole = value % 1 == 0;
    final formatted = isWhole
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return '$symbol$formatted';
  }

  String _formatInrCompact(double value) {
    if (value <= 0) return '₹0';
    if (value >= 10000000) {
      return '₹${(value / 10000000).toStringAsFixed(1)}Cr';
    }
    if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(1)}L';
    }
    if (value >= 1000) {
      return '₹${(value / 1000).toStringAsFixed(1)}K';
    }
    return '₹${value.toStringAsFixed(0)}';
  }

  double _parseAmount(AdminTransactionItem t) {
    return t.amount ?? 0;
  }

  String _titleCase(String value) {
    final v = value.trim();
    if (v.isEmpty) return '—';
    return v
        .toLowerCase()
        .split(RegExp(r'[_\s]+'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1))
        .join(' ');
  }

  (String, IconData, Color) _statusMeta(String raw, ColorScheme cs) {
    final s = raw.toLowerCase();
    if (s.contains('success')) {
      return ('SUCCESS', Icons.check_circle, cs.primary);
    }
    if (s.contains('pending') || s.contains('processing')) {
      return ('PENDING', Icons.schedule, cs.primary.withOpacity(0.7));
    }
    if (s.contains('fail') || s.contains('decline')) {
      return ('FAILED', Icons.cancel, cs.primary.withOpacity(0.5));
    }
    if (s.contains('refund')) {
      return ('REFUNDED', Icons.reply, cs.primary.withOpacity(0.5));
    }
    return ('UNKNOWN', Icons.help_outline, cs.onSurface.withOpacity(0.6));
  }

  String _transactionName(AdminTransactionItem t) {
    final raw = t.raw;
    String? name;
    if (raw['fromUser'] is Map) {
      name = (raw['fromUser'] as Map)['name']?.toString();
    }
    if ((name ?? '').isEmpty && raw['user'] is Map) {
      name = (raw['user'] as Map)['name']?.toString();
    }
    if ((name ?? '').isEmpty && raw['actor'] is Map) {
      name = (raw['actor'] as Map)['name']?.toString();
    }
    if ((name ?? '').isEmpty) {
      name = raw['fromUserName']?.toString();
    }
    if ((name ?? '').isEmpty) {
      name = raw['name']?.toString();
    }
    return _safe(name ?? '—');
  }

  String _transactionEmail(AdminTransactionItem t) {
    final raw = t.raw;
    String? email;
    if (raw['fromUser'] is Map) {
      email = (raw['fromUser'] as Map)['email']?.toString();
    }
    if ((email ?? '').isEmpty && raw['user'] is Map) {
      email = (raw['user'] as Map)['email']?.toString();
    }
    if ((email ?? '').isEmpty) {
      email = raw['fromUserEmail']?.toString();
    }
    if ((email ?? '').isEmpty) {
      email = raw['email']?.toString();
    }
    return _safe(email ?? '');
  }

  void _applyDateRange(String label) {
    final now = DateTime.now();
    DateTime from;
    DateTime to;
    if (label == 'Today') {
      from = DateTime(now.year, now.month, now.day);
      to = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (label == 'Last 7 days') {
      from = now.subtract(const Duration(days: 6));
      to = now;
    } else if (label == 'Last 30 days') {
      from = now.subtract(const Duration(days: 29));
      to = now;
    } else if (label == 'This month') {
      from = DateTime(now.year, now.month, 1);
      to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    } else {
      _fromDate = null;
      _toDate = null;
      return;
    }
    _fromDate = _dateOnly(from);
    _toDate = _dateOnly(to);
  }

  String _dateOnly(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
