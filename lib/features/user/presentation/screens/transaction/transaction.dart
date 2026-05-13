import 'dart:async';
import 'dart:io';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';
import 'package:open_vts/core/router/route_names.dart';

import 'package:open_vts/features/admin/domain/entities/admin_transaction_item.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:open_vts/features/user/presentation/components/appbars/user_home_appbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/user/di/user_providers.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_vts/core/state/update_local_ui_state.dart';

part 'transaction_helpers.dart';
part 'transaction_export.dart';
part 'transaction_widgets.dart';
part 'transaction_build.dart';

class TransactionScreen extends ConsumerStatefulWidget {
  const TransactionScreen({super.key});

  @override
  ConsumerState<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends ConsumerState<TransactionScreen> {
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

  Timer? _searchDebounce;
  int _loadGeneration = 0;

  late final _transactions = ref.read(userTransactionsAccessProvider);

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
    _loadGeneration++;
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

  Future<void> _loadTransactions() async {
    final generation = ++_loadGeneration;

    if (!mounted) return;
    updateLocalUiState(this, () => _loading = true);

    try {
      final page = await _transactions.getTransactions(
        query: _searchController.text.trim(),
        status: _statusQuery(_statusFilter),
        page: 1,
        limit: 100,
      );

      if (!mounted || generation != _loadGeneration) return;

      updateLocalUiState(this, () {
        _items = page.items;
        _loading = false;
        _errorShown = false;
      });
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return;
      updateLocalUiState(this, () {
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
      updateLocalUiState(this, () => _selectedRange = chosen);
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
      updateLocalUiState(this, () => _statusFilter = chosen);
      _loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) => _buildTransactionScreen(context);
}
