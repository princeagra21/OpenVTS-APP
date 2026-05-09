import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_vts/app/app_container.dart';
import 'package:open_vts/core/models/admin_list_item.dart';
import 'package:open_vts/core/models/superadmin_recent_transaction.dart';
import 'package:open_vts/core/network/api_exception.dart';
import 'package:open_vts/core/repositories/superadmin_repository.dart';
import 'package:open_vts/core/widgets/app_shimmer.dart';
import 'package:open_vts/modules/superadmin/components/transactions/record_manual_payment_screen.dart';
import 'package:open_vts/modules/superadmin/components/appbars/superadmin_home_appbar.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/design_system/theme/open_vts_theme.dart';

part 'payments_screen_export.dart';
part 'payments_screen_widgets.dart';
part 'payments_screen_build.dart';
part 'payments_screen_filter_sheets.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final CancelToken _loadToken = CancelToken();
  final TextEditingController _searchController = TextEditingController();
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

  SuperadminRepository _repoOrCreate() {
    _repo ??= AppContainer.instance.superadminRepository;
    return _repo!;
  }

  Future<void> _loadAdmins() async {
    if (!mounted) return;
    setState(() => _loadingAdmins = true);

    try {
      final res = await _repoOrCreate().getAdmins(
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAdmins = false);
      if (_adminsErrorShown) return;
      _adminsErrorShown = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't load admins.")));
    }
  }

  void _onFilterChanged() {
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    if (!mounted) return;
    AppLogger.debug('[Payments] Loading transactions');
    setState(() => _loadingTransactions = true);

    try {
      String? adminId;
      if (!_allAdminsSelected && _selectedAdmin != null) {
        adminId = _selectedAdmin!.id;
      }

      String? from, to;
      if (_selectedRange != null) {
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        if (_selectedRange == 'Today') {
          from = todayStart.toIso8601String();
          to = now.toIso8601String();
        } else if (_selectedRange == 'Last 7 days') {
          from = todayStart.subtract(const Duration(days: 7)).toIso8601String();
          to = now.toIso8601String();
        } else if (_selectedRange == 'Last 30 days') {
          from = todayStart
              .subtract(const Duration(days: 30))
              .toIso8601String();
          to = now.toIso8601String();
        } else if (_selectedRange == 'This month') {
          from = DateTime(now.year, now.month, 1).toIso8601String();
          to = now.toIso8601String();
        }
      }

      final res = await _repoOrCreate().getRecentTransactions(
        page: 1,
        limit: 200,
        adminId: adminId,
        from: from,
        to: to,
        status: _statusFilter == 'All' ? null : _statusFilter.toUpperCase(),
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
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

  Future<void> _refreshPayments() async {
    await _loadAdmins();
    await _loadTransactions();
  }

  @override
  Widget build(BuildContext context) => _buildPaymentsScreen(context);
}
