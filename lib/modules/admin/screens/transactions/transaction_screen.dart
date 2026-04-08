import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_transaction_item.dart';
import 'package:fleet_stack/core/models/admin_transactions_summary.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_transactions_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  // Endpoint truth table (FleetStack-API-Reference.md + Postman):
  // - GET /admin/transactions (query: search, status, page, limit, from, to)
  //   Response keys used: data.data.items | data.items | items
  // - GET /admin/transactions/analytics
  //   Response keys used: data.data (totalTransactions, totalsByCurrency, statusBreakdown)

  String _statusFilter = 'All';
  String? _selectedRange;
  String? _fromDate;
  String? _toDate;
  final TextEditingController _searchController = TextEditingController();

  List<AdminTransactionItem>? _items;
  AdminTransactionsSummary? _summary;
  double? _derivedProcessed30DaysAmount;

  bool _loading = false;
  bool _errorShown = false;
  bool _detailsApiUnavailableShown = false;
  bool _receiptApiUnavailableShown = false;

  CancelToken? _loadToken;
  Timer? _searchDebounce;

  ApiClient? _apiClient;
  AdminTransactionsRepository? _repo;

  AdminTransactionsRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminTransactionsRepository(api: _apiClient!);
    return _repo!;
  }

  void _showDebugUnavailableOnce({
    required String message,
    required bool alreadyShown,
    required void Function() markShown,
  }) {
    if (!kDebugMode || alreadyShown || !mounted) return;
    markShown();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadTransactions();
  }

  @override
  void dispose() {
    _loadToken?.cancel('TransactionScreen disposed');
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _loadTransactions();
    });
  }

  String? _statusQuery(String tab) {
    final normalized = AdminTransactionItem.normalizeStatus(tab);
    if (normalized.isEmpty || normalized == 'all') return null;
    return normalized;
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  void _showLoadErrorOnce(String message) {
    if (_errorShown || !mounted) return;
    _errorShown = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadTransactions() async {
    _loadToken?.cancel('Reload transactions');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final repo = _repoOrCreate();

      final listRes = await repo.getTransactions(
        search: _searchController.text.trim(),
        status: _statusQuery(_statusFilter),
        page: 1,
        limit: 100,
        from: _fromDate,
        to: _toDate,
        cancelToken: token,
      );

      final summaryRes = await repo.getTransactionsSummary(cancelToken: token);

      if (!mounted) return;

      List<AdminTransactionItem> items = const <AdminTransactionItem>[];
      AdminTransactionsSummary? summary;
      Object? firstError;

      listRes.when(
        success: (data) {
          items = data;
        },
        failure: (err) {
          firstError ??= err;
        },
      );

      summaryRes.when(
        success: (data) {
          summary = data;
        },
        failure: (err) {
          firstError ??= err;
        },
      );

      final derived = _computeProcessed30DaysAmount(items);

      setState(() {
        _items = items;
        _summary = summary;
        _derivedProcessed30DaysAmount = derived;
        _loading = false;
        if (firstError == null) {
          _errorShown = false;
        }
      });

      if (firstError != null && !_isCancelled(firstError!)) {
        _showLoadErrorOnce("Couldn't load transactions.");
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const <AdminTransactionItem>[];
        _summary = null;
        _derivedProcessed30DaysAmount = null;
        _loading = false;
      });
      _showLoadErrorOnce("Couldn't load transactions.");
    }
  }

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
    final slash = datePart.split('/');
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

  String _csvEscape(String value) {
    final needsQuote =
        value.contains(',') || value.contains('"') || value.contains('\n');
    final cleaned = value.replaceAll('"', '""');
    return needsQuote ? '"$cleaned"' : cleaned;
  }

  Future<void> _exportCsv(List<AdminTransactionItem> items) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export.')),
      );
      return;
    }
    final headers = [
      'ID',
      'Name',
      'Email',
      'Amount',
      'Currency',
      'Status',
      'Payment Mode',
      'Payment Type',
      'Reference',
      'Created At',
    ];
    final rows = <List<String>>[];
    for (final t in items) {
      final name = _transactionName(t);
      final email = _transactionEmail(t);
      rows.add([
        t.id,
        name,
        email,
        (t.amount ?? 0).toString(),
        t.currency,
        t.statusLabel,
        t.raw['paymentMode']?.toString() ?? '',
        t.raw['paymentType']?.toString() ?? '',
        t.raw['reference']?.toString() ?? '',
        t.createdAt,
      ]);
    }

    final buffer = StringBuffer();
    buffer.writeln(headers.map(_csvEscape).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(_csvEscape).join(','));
    }

    final filename =
        'transactions_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${Directory.systemTemp.path}/$filename');
    await file.writeAsString(buffer.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported CSV: ${file.path}')),
    );
  }

  Widget _summaryCard(
    BuildContext context, {
    required double width,
    required String title,
    required String value,
    required double titleSize,
    required double valueSize,
    required IconData icon,
    required double padding,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding - 2),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: titleSize,
                  height: 16 / 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
              Icon(icon, size: titleSize + 2, color: cs.onSurface),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: valueSize,
              height: 24 / 18,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required double scale,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? cs.surfaceVariant
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              fontSize: 12 * scale,
              height: 16 / 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.75),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 12 * scale,
              height: 16 / 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(width) + 6;
    final topPadding = MediaQuery.of(context).padding.top;
    final cs = Theme.of(context).colorScheme;
    final scale = (width / 420).clamp(0.9, 1.0);
    final labelStyle = GoogleFonts.roboto(
      fontSize: 12 * scale,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      color: cs.onSurface.withOpacity(0.7),
    );

    final query = _searchController.text.trim().toLowerCase();
    final allItems = _items ?? const <AdminTransactionItem>[];
    final filteredTransactions = allItems.where((t) {
      final status = t.statusLabel.toLowerCase();
      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Success' && status.contains('success')) ||
          (_statusFilter == 'Pending' &&
              (status.contains('pending') || status.contains('processing'))) ||
          (_statusFilter == 'Failed' && status.contains('fail'));
      if (!matchesStatus) return false;
      if (query.isEmpty) return true;
      final name = _transactionName(t).toLowerCase();
      final email = _transactionEmail(t).toLowerCase();
      final reference = (t.raw['reference']?.toString() ?? '').toLowerCase();
      return name.contains(query) ||
          email.contains(query) ||
          reference.contains(query);
    }).toList();

    final totalTxns = allItems.length;
    final success = allItems.where((t) {
      final s = t.statusLabel.toLowerCase();
      return s.contains('success');
    }).toList();
    final pending = allItems.where((t) {
      final s = t.statusLabel.toLowerCase();
      return s.contains('pending') || s.contains('processing');
    }).toList();
    final failed = allItems.where((t) {
      final s = t.statusLabel.toLowerCase();
      return s.contains('fail') || s.contains('decline');
    }).toList();
    final revenue =
        success.fold<double>(0, (sum, t) => sum + _parseAmount(t));
    final successRate =
        totalTxns == 0 ? 0 : ((success.length / totalTxns) * 100).round();

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                padding,
                topPadding + AppUtils.appBarHeightCustom + 28,
                padding,
                padding,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cs.onSurface.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Transactions',
                                style: AppUtils.headlineSmallBase.copyWith(
                                  fontSize:
                                      AdaptiveUtils.getSubtitleFontSize(width) +
                                          2,
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface,
                                ),
                              ),
                              InkWell(
                                onTap: () => context.push('/admin/payments/add'),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.add,
                                          size: 16, color: Colors.white),
                                      SizedBox(width: 6),
                                      Text(
                                        'Record',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const SizedBox(height: 4),
                          Text('Date Range', style: labelStyle),
                          const SizedBox(height: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final chosen =
                                  await showModalBottomSheet<String>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: cs.surface,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                builder: (ctx) {
                                  final items = [
                                    'Today',
                                    'Last 7 days',
                                    'Last 30 days',
                                    'This month',
                                  ];
                                  return SafeArea(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: cs.onSurface
                                                  .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Select Date Range',
                                            style: GoogleFonts.roboto(
                                              fontWeight: FontWeight.w600,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            height: MediaQuery.of(ctx)
                                                    .size
                                                    .height *
                                                0.7,
                                            child: ListView.separated(
                                              itemCount: items.length,
                                              separatorBuilder: (_, __) =>
                                                  const SizedBox(height: 8),
                                              itemBuilder: (_, index) {
                                                final item = items[index];
                                                return ListTile(
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                  ),
                                                  title: Text(
                                                    item,
                                                    style: GoogleFonts.roboto(
                                                      fontSize: 14 * scale,
                                                      height: 20 / 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  onTap: () =>
                                                      Navigator.pop(ctx, item),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                              if (chosen != null) {
                                setState(() => _selectedRange = chosen);
                                _applyDateRange(chosen);
                                _loadTransactions();
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: cs.onSurface.withOpacity(0.12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedRange ?? 'Select range',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.roboto(
                                        fontSize: 14 * scale,
                                        height: 20 / 14,
                                        fontWeight: FontWeight.w500,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.expand_more,
                                    color: cs.onSurface.withOpacity(0.6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(
                        AdaptiveUtils.getHorizontalPadding(width),
                      ),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: cs.onSurface.withOpacity(0.08),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overview',
                            style: AppUtils.headlineSmallBase.copyWith(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) + 2,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                          SizedBox(
                            height:
                                AdaptiveUtils.getLeftSectionSpacing(width) + 8,
                          ),
                          if (_loading)
                            const AppShimmer(
                              width: double.infinity,
                              height: 120,
                              radius: 16,
                            )
                          else
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final spacing = AdaptiveUtils
                                        .getLeftSectionSpacing(width) +
                                    6;
                                final maxWidth = constraints.maxWidth;
                                final columns = 2;
                                final totalSpacing = spacing * (columns - 1);
                                final itemWidth =
                                    (maxWidth - totalSpacing) / columns;
                                final titleFontSize =
                                    AdaptiveUtils.getTitleFontSize(width) + 1;
                                final valueFontSize =
                                    AdaptiveUtils.getSubtitleFontSize(width) + 4;
                                return Wrap(
                                  spacing: spacing,
                                  runSpacing: spacing,
                                  children: [
                                    _summaryCard(
                                      context,
                                      width: itemWidth,
                                      title: 'REVENUE',
                                      value: _formatInrCompact(revenue),
                                      titleSize: titleFontSize,
                                      valueSize: valueFontSize,
                                      icon: Symbols.payments,
                                      padding: spacing,
                                    ),
                                    _summaryCard(
                                      context,
                                      width: itemWidth,
                                      title: 'SUCCESSFUL',
                                      value: '${success.length}',
                                      titleSize: titleFontSize,
                                      valueSize: valueFontSize,
                                      icon: Symbols.check_circle,
                                      padding: spacing,
                                    ),
                                    _summaryCard(
                                      context,
                                      width: itemWidth,
                                      title: 'PENDING',
                                      value: '${pending.length}',
                                      titleSize: titleFontSize,
                                      valueSize: valueFontSize,
                                      icon: Symbols.schedule,
                                      padding: spacing,
                                    ),
                                    _summaryCard(
                                      context,
                                      width: itemWidth,
                                      title: 'FAILED',
                                      value: '${failed.length}',
                                      titleSize: titleFontSize,
                                      valueSize: valueFontSize,
                                      icon: Symbols.cancel,
                                      padding: spacing,
                                    ),
                                    _summaryCard(
                                      context,
                                      width: itemWidth,
                                      title: 'SUCCESS RATE',
                                      value: '$successRate%',
                                      titleSize: titleFontSize,
                                      valueSize: valueFontSize,
                                      icon: Symbols.percent,
                                      padding: spacing,
                                    ),
                                    _summaryCard(
                                      context,
                                      width: itemWidth,
                                      title: 'TOTAL TXNS',
                                      value: '$totalTxns',
                                      titleSize: titleFontSize,
                                      valueSize: valueFontSize,
                                      icon: Symbols.receipt_long,
                                      padding: spacing,
                                    ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cs.onSurface.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transaction Status',
                            style: AppUtils.headlineSmallBase.copyWith(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) + 2,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _statusPill(
                                context,
                                label: 'Success',
                                value: '$successRate%',
                                color: cs.primary,
                                scale: scale,
                              ),
                              const SizedBox(width: 10),
                              _statusPill(
                                context,
                                label: 'Pending',
                                value:
                                    '${totalTxns == 0 ? 0 : ((pending.length / totalTxns) * 100).round()}%',
                                color: cs.primary.withOpacity(0.7),
                                scale: scale,
                              ),
                              const SizedBox(width: 10),
                              _statusPill(
                                context,
                                label: 'Failed',
                                value:
                                    '${totalTxns == 0 ? 0 : ((failed.length / totalTxns) * 100).round()}%',
                                color: cs.primary.withOpacity(0.5),
                                scale: scale,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: totalTxns == 0
                                  ? 0
                                  : (success.length / totalTxns).clamp(0, 1),
                              minHeight: 8,
                              backgroundColor: cs.onSurface.withOpacity(0.08),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(cs.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: cs.surfaceVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transactions',
                            style: AppUtils.headlineSmallBase.copyWith(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) + 2,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height:
                                AdaptiveUtils.getHorizontalPadding(width) * 3.5,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: cs.onSurface.withOpacity(0.1),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: GoogleFonts.roboto(
                                fontSize: 14 * scale,
                                height: 20 / 14,
                                color: cs.onSurface,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search name, email, or reference',
                                hintStyle: GoogleFonts.roboto(
                                  color: cs.onSurface.withOpacity(0.5),
                                  fontSize: 12 * scale,
                                  height: 16 / 12,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  size: AdaptiveUtils.getIconSize(width),
                                  color: cs.onSurface,
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal:
                                      AdaptiveUtils.getHorizontalPadding(width),
                                  vertical:
                                      AdaptiveUtils.getHorizontalPadding(width),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    final chosen =
                                        await showModalBottomSheet<String>(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: cs.surface,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16),
                                        ),
                                      ),
                                      builder: (ctx) {
                                        final items = [
                                          'All',
                                          'Success',
                                          'Pending',
                                          'Failed',
                                        ];
                                        return SafeArea(
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              16,
                                              16,
                                              16,
                                              8,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 42,
                                                  height: 4,
                                                  decoration: BoxDecoration(
                                                    color: cs.onSurface
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(2),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  'Filter Status',
                                                  style: GoogleFonts.roboto(
                                                    fontWeight: FontWeight.w600,
                                                    color: cs.onSurface,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                SizedBox(
                                                  height: MediaQuery.of(ctx)
                                                          .size
                                                          .height *
                                                      0.7,
                                                  child: ListView.separated(
                                                    itemCount: items.length,
                                                    separatorBuilder: (_, __) =>
                                                        const SizedBox(
                                                      height: 8,
                                                    ),
                                                    itemBuilder: (_, index) {
                                                      final item = items[index];
                                                      return ListTile(
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 6,
                                                        ),
                                                        title: Text(
                                                          item,
                                                          style:
                                                              GoogleFonts.roboto(
                                                            fontSize: 14 * scale,
                                                            height: 20 / 14,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                        onTap: () =>
                                                            Navigator.pop(
                                                          ctx,
                                                          item,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                    if (chosen != null) {
                                      setState(() => _statusFilter = chosen);
                                      _loadTransactions();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: cs.onSurface.withOpacity(0.12),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.tune,
                                          size: 16 * scale,
                                          color: cs.onSurface.withOpacity(0.7),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Filter',
                                          style: GoogleFonts.roboto(
                                            fontSize: 12 * scale,
                                            height: 16 / 12,
                                            fontWeight: FontWeight.w600,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _loadTransactions,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: cs.onSurface.withOpacity(0.12),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.refresh,
                                          size: 16 * scale,
                                          color: cs.onSurface.withOpacity(0.7),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Refresh',
                                          style: GoogleFonts.roboto(
                                            fontSize: 12 * scale,
                                            height: 16 / 12,
                                            fontWeight: FontWeight.w600,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _exportCsv(filteredTransactions),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: cs.onSurface.withOpacity(0.12),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.upload,
                                          size: 16 * scale,
                                          color: cs.onSurface.withOpacity(0.7),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Export',
                                          style: GoogleFonts.roboto(
                                            fontSize: 12 * scale,
                                            height: 16 / 12,
                                            fontWeight: FontWeight.w600,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...filteredTransactions.map((t) {
                            final name = _transactionName(t);
                            final dateText = _formatDateTime(t.createdAt);
                            final amount = _formatAmount(t.amount, t.currency);
                            final (statusText, statusIcon, statusColor) =
                                _statusMeta(t.statusLabel, cs);
                            final mode = _titleCase(
                              t.raw['paymentMode']?.toString() ?? '—',
                            );
                            final type = _titleCase(
                              t.raw['paymentType']?.toString() ?? '—',
                            );
                            final reference = t.raw['reference']?.toString() ??
                                t.reference;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 40 * scale,
                                          height: 40 * scale,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            color: Theme.of(context)
                                                        .brightness ==
                                                    Brightness.dark
                                                ? cs.surfaceVariant
                                                : Colors.grey.shade50,
                                            border: Border.all(
                                              color:
                                                  cs.outline.withOpacity(0.3),
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.person_outline,
                                            size: 18 * scale,
                                            color: cs.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: GoogleFonts.roboto(
                                                  fontSize: 14 * scale,
                                                  height: 20 / 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: cs.onSurface,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                dateText,
                                                style: GoogleFonts.roboto(
                                                  fontSize: 12 * scale,
                                                  height: 16 / 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: cs.onSurface
                                                      .withOpacity(0.6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              amount,
                                              style: GoogleFonts.roboto(
                                                fontSize: 14 * scale,
                                                height: 20 / 14,
                                                fontWeight: FontWeight.w700,
                                                color: cs.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? cs.surfaceVariant
                                                    : Colors.grey.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    statusIcon,
                                                    size: 14 * scale,
                                                    color: statusColor,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    statusText,
                                                    style: GoogleFonts.roboto(
                                                      fontSize: 11 * scale,
                                                      height: 14 / 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: statusColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: cs.onSurface
                                                    .withOpacity(0.12),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Mode',
                                                  style: GoogleFonts.roboto(
                                                    fontSize: 11 * scale,
                                                    height: 14 / 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: cs.onSurface
                                                        .withOpacity(0.6),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  mode,
                                                  style: GoogleFonts.roboto(
                                                    fontSize: 13 * scale,
                                                    height: 18 / 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: cs.onSurface,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: cs.onSurface
                                                    .withOpacity(0.12),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Type',
                                                  style: GoogleFonts.roboto(
                                                    fontSize: 11 * scale,
                                                    height: 14 / 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: cs.onSurface
                                                        .withOpacity(0.6),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  type,
                                                  style: GoogleFonts.roboto(
                                                    fontSize: 13 * scale,
                                                    height: 18 / 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: cs.onSurface,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: cs.onSurface.withOpacity(0.12),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '# Reference',
                                            style: GoogleFonts.roboto(
                                              fontSize: 11 * scale,
                                              height: 14 / 11,
                                              fontWeight: FontWeight.w500,
                                              color: cs.onSurface
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            reference.isEmpty ? '—' : reference,
                                            style: GoogleFonts.roboto(
                                              fontSize: 13 * scale,
                                              height: 18 / 13,
                                              fontWeight: FontWeight.w600,
                                              color: cs.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: padding,
            right: padding,
            top: 0,
            child: Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF0A0A0A)
                  : const Color(0xFFF5F5F7),
              child: const AdminHomeAppBar(
                title: 'Transactions',
                leadingIcon: Icons.receipt_long,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
