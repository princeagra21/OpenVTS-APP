import 'dart:async';
import 'dart:io';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';
import 'package:open_vts/core/router/route_names.dart';

import 'package:open_vts/features/admin/domain/entities/admin_transaction_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_transactions_summary.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/features/admin/presentation/components/appbars/admin_home_appbar.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/admin/di/admin_operations_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_vts/core/state/update_local_ui_state.dart';

part 'transaction_screen_helpers.dart';
part 'transaction_screen_export.dart';
part 'transaction_screen_widgets.dart';
part 'transaction_screen_build.dart';

class TransactionScreen extends ConsumerStatefulWidget {
  const TransactionScreen({super.key});

  @override
  ConsumerState<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends ConsumerState<TransactionScreen> {
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

  Timer? _searchDebounce;


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
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      updateLocalUiState(this, () {});
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
    if (!mounted) return;
    updateLocalUiState(this, () => _loading = true);

    final ok = await ref.read(adminTransactionsControllerProvider.notifier).load(
          search: _searchController.text.trim(),
          status: _statusQuery(_statusFilter),
          page: 1,
          limit: 100,
          from: _fromDate,
          to: _toDate,
        );
    if (!mounted) return;
    final nextState = ref.read(adminTransactionsControllerProvider);
    final derived = _computeProcessed30DaysAmount(nextState.items);

    updateLocalUiState(this, () {
      _items = nextState.items;
      _summary = nextState.summary;
      _derivedProcessed30DaysAmount = derived;
      _loading = false;
      if (ok) _errorShown = false;
    });

    if (!ok) {
      final msg = nextState.error?.message.trim().isNotEmpty == true
          ? nextState.error!.message
          : "Couldn't load transactions.";
      _showLoadErrorOnce(msg);
    }
  }

  @override
  Widget build(BuildContext context) => _buildTransactionScreen(context);
}
