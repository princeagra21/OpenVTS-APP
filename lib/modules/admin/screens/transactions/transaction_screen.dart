import 'dart:async';
import 'dart:io';
import 'package:open_vts/app/app_container.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/design_system/theme/open_vts_theme.dart';
import 'package:open_vts/app/router/app_route_paths.dart';

import 'package:dio/dio.dart';
import 'package:open_vts/core/models/admin_transaction_item.dart';
import 'package:open_vts/core/models/admin_transactions_summary.dart';
import 'package:open_vts/core/network/api_exception.dart';
import 'package:open_vts/core/repositories/admin_transactions_repository.dart';
import 'package:open_vts/core/widgets/app_shimmer.dart';
import 'package:open_vts/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

part 'transaction_screen_helpers.dart';
part 'transaction_screen_export.dart';
part 'transaction_screen_widgets.dart';
part 'transaction_screen_build.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  // Endpoint truth table (API reference documentation + Postman):
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
  final bool _detailsApiUnavailableShown = false;
  final bool _receiptApiUnavailableShown = false;

  CancelToken? _loadToken;
  Timer? _searchDebounce;

  AdminTransactionsRepository? _repo;

  AdminTransactionsRepository _repoOrCreate() {
    _repo ??= AppContainer.instance.adminTransactionsRepository;
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

  Future<void> _openRecordTransaction() async {
    final result = await context.push(AppRoutePaths.adminPaymentsAdd);
    if (!mounted) return;
    if (result == true) {
      _loadTransactions();
    }
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

  @override
  Widget build(BuildContext context) => _buildTransactionScreen(context);
}
