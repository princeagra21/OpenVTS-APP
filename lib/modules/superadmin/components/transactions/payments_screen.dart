import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_list_item.dart';
import 'package:fleet_stack/core/models/superadmin_recent_transaction.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/components/transactions/record_manual_payment_screen.dart';
import 'package:fleet_stack/modules/superadmin/components/appbars/superadmin_home_appbar.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/superadmin/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final CancelToken _loadToken = CancelToken();
  final TextEditingController _searchController = TextEditingController();
  ApiClient? _api;
  SuperadminRepository? _repo;
  bool _loadingAdmins = false;
  bool _adminsErrorShown = false;
  List<AdminListItem> _admins = <AdminListItem>[];
  AdminListItem? _selectedAdmin;
  bool _allAdminsSelected = true;
  String? _selectedRange;
  bool _loadingTransactions = false;
  bool _transactionsErrorShown = false;
  List<SuperadminRecentTransaction> _transactions =
      <SuperadminRecentTransaction>[];
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAdmins();
      _loadTransactions();
    });
  }

  @override
  void dispose() {
    _loadToken.cancel('PaymentsScreen disposed');
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAdmins() async {
    if (!mounted) return;
    setState(() => _loadingAdmins = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);
      final res = await _repo!.getAdmins(
        page: 1,
        limit: 200,
        cancelToken: _loadToken,
      );
      if (!mounted) return;
      res.when(
        success: (items) {
          setState(() {
            _loadingAdmins = false;
            _admins = items;
            _selectedAdmin = items.isNotEmpty ? items.first : null;
          });
        },
        failure: (err) {
          setState(() => _loadingAdmins = false);
          if (_adminsErrorShown) return;
          _adminsErrorShown = true;
          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load admins.'
              : "Couldn't load admins.";
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAdmins = false);
      if (_adminsErrorShown) return;
      _adminsErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load admins.")),
      );
    }
  }

  Future<void> _loadTransactions() async {
    if (!mounted) return;
    debugPrint('[Payments] Loading transactions');
    setState(() => _loadingTransactions = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);
      final res = await _repo!.getRecentTransactions(
        page: 1,
        limit: 200,
        cancelToken: _loadToken,
      );
      if (!mounted) return;
      res.when(
        success: (items) {
          setState(() {
            _loadingTransactions = false;
            _transactions = items;
          });
        },
        failure: (err) {
          setState(() => _loadingTransactions = false);
          if (_transactionsErrorShown) return;
          _transactionsErrorShown = true;
          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load transactions.'
              : "Couldn't load transactions.";
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingTransactions = false);
      if (_transactionsErrorShown) return;
      _transactionsErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load transactions.")),
      );
    }
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

  double _parseAmount(String raw) {
    final cleaned = raw.replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? 0;
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

  String _formatCurrency(String amount, String currency) {
    if (amount.trim().isEmpty) return '—';
    final symbol = currency.toUpperCase() == 'INR' ? '₹' : currency;
    return '$symbol${amount.trim()}';
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
    return ('UNKNOWN', Icons.help_outline, cs.onSurface.withOpacity(0.6));
  }

  String _csvEscape(String value) {
    final needsQuote =
        value.contains(',') || value.contains('"') || value.contains('\n');
    final cleaned = value.replaceAll('"', '""');
    return needsQuote ? '"$cleaned"' : cleaned;
  }

  Future<void> _exportCsv(List<SuperadminRecentTransaction> items) async {
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
      rows.add([
        t.id,
        t.fromUserName.isNotEmpty ? t.fromUserName : t.actorName,
        t.fromUserEmail,
        t.amount,
        t.currency,
        t.status,
        t.raw['paymentMode']?.toString() ?? '',
        t.raw['paymentType']?.toString() ?? '',
        t.raw['reference']?.toString() ?? '',
        t.time,
      ]);
    }

    final buffer = StringBuffer();
    buffer.writeln(headers.map(_csvEscape).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(_csvEscape).join(','));
    }

    final filename =
        'payments_${DateTime.now().millisecondsSinceEpoch}.csv';
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
      constraints: const BoxConstraints(minHeight: 110),
      padding: EdgeInsets.symmetric(
        horizontal: padding + 2,
        vertical: padding + 20,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppUtils.bodySmallBase.copyWith(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.65),
                  ),
                ),
              ),
              Icon(
                icon,
                size: titleSize + 6,
                color: cs.onSurface.withOpacity(0.5),
              ),
            ],
          ),
          SizedBox(height: padding + 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppUtils.headlineSmallBase.copyWith(
              fontSize: valueSize,
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
    return Expanded(
      child: Row(
        children: [
          Container(
            height: 8,
            width: 8,
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
            style: GoogleFonts.inter(
              fontSize: 12 * scale,
              height: 16 / 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.75),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.inter(
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(width) + 6;
    final topPadding = MediaQuery.of(context).padding.top;
    final cs = Theme.of(context).colorScheme;
    final scale = (width / 420).clamp(0.9, 1.0);
    final labelStyle = GoogleFonts.inter(
      fontSize: 12 * scale,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      color: cs.onSurface.withOpacity(0.7),
    );
    final query = _searchController.text.trim().toLowerCase();
    final filteredTransactions = _transactions.where((t) {
      final status = t.status.toLowerCase();
      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Success' && status.contains('success')) ||
          (_statusFilter == 'Pending' &&
              (status.contains('pending') || status.contains('processing'))) ||
          (_statusFilter == 'Failed' &&
              (status.contains('fail') || status.contains('decline')));
      if (!matchesStatus) return false;
      if (query.isEmpty) return true;
      final name = t.fromUserName.toLowerCase();
      final email = t.fromUserEmail.toLowerCase();
      final reference = (t.raw['reference']?.toString() ?? '').toLowerCase();
      return name.contains(query) ||
          email.contains(query) ||
          reference.contains(query);
    }).toList();
    final totalTxns = _transactions.length;
    final success = _transactions.where((t) {
      final s = t.status.toLowerCase();
      return s.contains('success');
    }).toList();
    final pending = _transactions.where((t) {
      final s = t.status.toLowerCase();
      return s.contains('pending') || s.contains('processing');
    }).toList();
    final failed = _transactions.where((t) {
      final s = t.status.toLowerCase();
      return s.contains('fail') || s.contains('decline');
    }).toList();
    final revenue = success.fold<double>(
      0,
      (sum, t) => sum + _parseAmount(t.amount),
    );
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
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Payment',
                              style: AppUtils.headlineSmallBase.copyWith(
                                fontSize:
                                    AdaptiveUtils.getSubtitleFontSize(width) +
                                        2,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const RecordManualPaymentScreen(),
                                  ),
                                );
                              },
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
                        Text('Admin', style: labelStyle),
                        const SizedBox(height: 8),
                        if (_loadingAdmins)
                          const AppShimmer(
                            width: double.infinity,
                            height: 52,
                            radius: 12,
                          )
                        else
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final chosen =
                                  await showModalBottomSheet<AdminListItem>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: cs.surface,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                builder: (ctx) {
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
                                            'Select Admin',
                                            style: GoogleFonts.inter(
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
                                              itemCount: _admins.length,
                                              separatorBuilder: (_, __) =>
                                                  const SizedBox(height: 8),
                                              itemBuilder: (_, index) {
                                                final admin = _admins[index];
                                                final title = admin
                                                        .name.isNotEmpty
                                                    ? admin.name
                                                    : admin.email.isNotEmpty
                                                        ? admin.email
                                                        : admin.id;
                                                final subtitle =
                                                    admin.email.isNotEmpty
                                                        ? admin.email
                                                        : admin.id;
                                                return ListTile(
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                  ),
                                                  title: Text(
                                                    title,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 14 * scale,
                                                      height: 20 / 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    subtitle,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12 * scale,
                                                      height: 16 / 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: cs.onSurface
                                                          .withOpacity(0.6),
                                                    ),
                                                  ),
                                                  onTap: () =>
                                                      Navigator.pop(ctx, admin),
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
                                setState(() {
                                  _selectedAdmin = chosen;
                                  _allAdminsSelected = false;
                                });
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
                                      _allAdminsSelected
                                          ? 'All Admins'
                                          : (_selectedAdmin != null
                                              ? (_selectedAdmin!.name.isNotEmpty
                                                  ? _selectedAdmin!.name
                                                  : _selectedAdmin!
                                                          .email.isNotEmpty
                                                      ? _selectedAdmin!.email
                                                      : _selectedAdmin!.id)
                                              : 'All Admins'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
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
                        const SizedBox(height: 12),
                        Text('Date Range', style: labelStyle),
                        const SizedBox(height: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            final chosen = await showModalBottomSheet<String>(
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
                                          style: GoogleFonts.inter(
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
                                                  style: GoogleFonts.inter(
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
                                    style: GoogleFonts.inter(
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
                        if (_loadingTransactions)
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
                            style: GoogleFonts.inter(
                              fontSize: 14 * scale,
                              height: 20 / 14,
                              color: cs.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search name, email, or reference',
                              hintStyle: GoogleFonts.inter(
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
                                                style: GoogleFonts.inter(
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
                                                            GoogleFonts.inter(
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
                                      style: GoogleFonts.inter(
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
                                      style: GoogleFonts.inter(
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
                                      style: GoogleFonts.inter(
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
                          final name = t.fromUserName.isNotEmpty
                              ? t.fromUserName
                              : (t.actorName.isNotEmpty ? t.actorName : '—');
                          final dateText = _formatDateTime(t.time);
                          final amount = _formatCurrency(t.amount, t.currency);
                          final (statusText, statusIcon, statusColor) =
                              _statusMeta(t.status, cs);
                          final mode = _titleCase(
                            t.raw['paymentMode']?.toString() ?? '—',
                          );
                          final type = _titleCase(
                            t.raw['paymentType']?.toString() ?? '—',
                          );
                          final reference =
                              t.raw['reference']?.toString() ?? '—';

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
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? cs.surfaceVariant
                                              : Colors.grey.shade50,
                                          border: Border.all(
                                            color: cs.outline.withOpacity(0.3),
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
                                              style: GoogleFonts.inter(
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
                                              style: GoogleFonts.inter(
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
                                            style: GoogleFonts.inter(
                                              fontSize: 14 * scale,
                                              height: 20 / 14,
                                              fontWeight: FontWeight.w700,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
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
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11 * scale,
                                                    height: 14 / 11,
                                                    fontWeight: FontWeight.w600,
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
                                                style: GoogleFonts.inter(
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
                                                style: GoogleFonts.inter(
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
                                                style: GoogleFonts.inter(
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
                                                style: GoogleFonts.inter(
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
                                        color:
                                            cs.onSurface.withOpacity(0.12),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                  Text(
                                    '# Reference',
                                    style: GoogleFonts.inter(
                                      fontSize: 11 * scale,
                                      height: 14 / 11,
                                            fontWeight: FontWeight.w500,
                                            color: cs.onSurface
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                  Text(
                                    reference,
                                          style: GoogleFonts.inter(
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
              child: const SuperAdminHomeAppBar(
                title: 'Payments',
                leadingIcon: Icons.credit_card,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
