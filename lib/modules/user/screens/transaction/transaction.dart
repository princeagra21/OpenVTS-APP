import 'dart:async';
import 'dart:io';
import 'package:open_vts/app/app_container.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/design_system/theme/open_vts_theme.dart';
import 'package:open_vts/app/router/app_route_paths.dart';

import 'package:dio/dio.dart';
import 'package:open_vts/core/models/admin_transaction_item.dart';
import 'package:open_vts/core/network/api_exception.dart';
import 'package:open_vts/core/repositories/user_transactions_repository.dart';
import 'package:open_vts/core/widgets/app_shimmer.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:open_vts/modules/user/components/appbars/user_home_appbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

part 'transaction_helpers.dart';
part 'transaction_export.dart';
part 'transaction_widgets.dart';
part 'transaction_build.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  // Endpoint truth table (API reference documentation + Postman):
  // - GET /user/transactions (query: q, status, page, limit)

  String _statusFilter = 'All';
  String? _selectedRange;
  String? _fromDate;
  String? _toDate;
  final TextEditingController _searchController = TextEditingController();

  List<AdminTransactionItem>? _items;

  bool _loading = false;
  bool _errorShown = false;
  final bool _detailsApiUnavailableShown = false;
  final bool _receiptApiUnavailableShown = false;

  CancelToken? _loadToken;
  Timer? _searchDebounce;

  UserTransactionsRepository? _repo;

  UserTransactionsRepository _repoOrCreate() {
    _repo ??= AppContainer.instance.userTransactionsRepository;
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
        query: _searchController.text.trim(),
        status: _statusQuery(_statusFilter),
        page: 1,
        limit: 100,
        cancelToken: token,
      );

      if (!mounted) return;

      List<AdminTransactionItem> items = const <AdminTransactionItem>[];
      Object? firstError;

      listRes.when(
        success: (data) {
          items = data.items;
        },
        failure: (err) {
          firstError ??= err;
        },
      );

      setState(() {
        _items = items;
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
        _loading = false;
      });
      _showLoadErrorOnce("Couldn't load transactions.");
    }
  }

  Future<void> _pickDateRangeFilter(
    BuildContext context,
    ColorScheme cs,
    double scale,
  ) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final items = ['Today', 'Last 7 days', 'Last 30 days', 'This month'];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Select Date Range',
                  style: AppFonts.roboto(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.7,
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final item = items[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6,
                        ),
                        title: Text(
                          item,
                          style: AppFonts.roboto(
                            fontSize: 14 * scale,
                            height: 20 / 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () => Navigator.pop(ctx, item),
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
  }

  Future<void> _pickStatusFilter(
    BuildContext context,
    ColorScheme cs,
    double scale,
  ) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final items = ['All', 'Success', 'Pending', 'Failed'];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Filter Status',
                  style: AppFonts.roboto(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.7,
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final item = items[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6,
                        ),
                        title: Text(
                          item,
                          style: AppFonts.roboto(
                            fontSize: 14 * scale,
                            height: 20 / 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () => Navigator.pop(ctx, item),
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
  }

  @override
  Widget build(BuildContext context) => _buildTransactionScreen(context);
}
