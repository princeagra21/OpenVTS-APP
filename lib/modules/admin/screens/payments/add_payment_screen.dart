import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_user_list_item.dart';
import 'package:fleet_stack/core/models/admin_vehicle_preview_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_payments_repository.dart';
import 'package:fleet_stack/core/repositories/admin_users_repository.dart';
import 'package:fleet_stack/core/repositories/admin_vehicle_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:flutter/material.dart';

class AddPaymentScreen extends StatefulWidget {
  const AddPaymentScreen({super.key});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  static const List<String> _paymentModes = <String>[
    'BANK_TRANSFER',
    'CASH',
    'UPI',
    'CARD',
    'CHEQUE',
    'OTHER',
  ];

  ApiClient? _apiClient;
  AdminUsersRepository? _usersRepo;
  AdminVehicleRepository? _vehicleRepo;
  AdminPaymentsRepository? _paymentsRepo;
  CancelToken? _loadToken;
  CancelToken? _submitToken;

  List<AdminUserListItem> _users = const <AdminUserListItem>[];
  List<AdminVehiclePreviewItem> _vehicles = const <AdminVehiclePreviewItem>[];
  AdminUserListItem? _selectedUser;
  final Set<String> _selectedVehicleIds = <String>{};
  String _paymentMode = 'BANK_TRANSFER';

  bool _loading = true;
  bool _submitting = false;

  ApiClient _apiOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    return _apiClient!;
  }

  AdminUsersRepository _usersRepoOrCreate() {
    _usersRepo ??= AdminUsersRepository(api: _apiOrCreate());
    return _usersRepo!;
  }

  AdminVehicleRepository _vehicleRepoOrCreate() {
    _vehicleRepo ??= AdminVehicleRepository(api: _apiOrCreate());
    return _vehicleRepo!;
  }

  AdminPaymentsRepository _paymentsRepoOrCreate() {
    _paymentsRepo ??= AdminPaymentsRepository(api: _apiOrCreate());
    return _paymentsRepo!;
  }

  @override
  void initState() {
    super.initState();
    _loadRefs();
  }

  @override
  void dispose() {
    _loadToken?.cancel('Add payment disposed');
    _submitToken?.cancel('Add payment disposed');
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _userLabel(AdminUserListItem item) {
    final name = item.fullName.trim();
    final username = item.username.trim();
    if (username.isEmpty) return name;
    return '$name (@$username)';
  }

  Future<void> _loadRefs() async {
    _loadToken?.cancel('Reload add payment refs');
    final token = CancelToken();
    _loadToken = token;
    setState(() => _loading = true);

    try {
      final usersRes = await _usersRepoOrCreate().getUsers(
        page: 1,
        limit: 200,
        cancelToken: token,
      );
      final vehiclesRes = await _vehicleRepoOrCreate().getVehiclePreviewList(
        limit: 1000,
        cancelToken: token,
      );

      List<AdminUserListItem> users = const <AdminUserListItem>[];
      List<AdminVehiclePreviewItem> vehicles = const <AdminVehiclePreviewItem>[];
      usersRes.when(success: (d) => users = d, failure: (_) {});
      vehiclesRes.when(success: (d) => vehicles = d, failure: (_) {});

      if (!mounted) return;
      setState(() {
        _users = users;
        _vehicles = vehicles;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack("Couldn't load users/vehicles.");
    }
  }

  Future<T?> _showOptionSheet<T>({
    required String title,
    required List<T> items,
    required String Function(T item) labelFor,
  }) {
    String query = '';
    final cs = Theme.of(context).colorScheme;
    final searchController = TextEditingController();

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.7,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final filtered = items.where((e) {
                final t = labelFor(e).toLowerCase();
                return t.contains(query.toLowerCase());
              }).toList();

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchController,
                      onChanged: (v) => setSheetState(() => query = v.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final item = filtered[i];
                          return ListTile(
                            title: Text(labelFor(item)),
                            onTap: () => Navigator.pop(ctx, item),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openVehiclesSheet() async {
    final cs = Theme.of(context).colorScheme;
    String query = '';
    final search = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.8,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final filtered = _vehicles.where((v) {
                final t =
                    '${v.plateNumber} ${v.imei} ${v.statusLabel}'.toLowerCase();
                return t.contains(query.toLowerCase());
              }).toList();
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Vehicles',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: search,
                      onChanged: (v) => setSheetState(() => query = v.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search vehicle',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final v = filtered[i];
                          final id = v.id.trim();
                          final checked = _selectedVehicleIds.contains(id);
                          return CheckboxListTile(
                            value: checked,
                            onChanged: (_) {
                              setState(() {
                                if (checked) {
                                  _selectedVehicleIds.remove(id);
                                } else {
                                  _selectedVehicleIds.add(id);
                                }
                              });
                              setSheetState(() {});
                            },
                            title: Text(v.plateNumber),
                            subtitle: Text(v.imei.isEmpty ? '—' : v.imei),
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_selectedUser == null) {
      _snack('Select user.');
      return;
    }
    if (_selectedVehicleIds.isEmpty) {
      _snack('Select at least one vehicle.');
      return;
    }

    _submitToken?.cancel('Replace renew submit');
    final token = CancelToken();
    _submitToken = token;

    setState(() => _submitting = true);
    final res = await _paymentsRepoOrCreate().createRenewPayment(
      userId: _selectedUser!.id,
      vehicleIds: _selectedVehicleIds.toList(),
      paymentMode: _paymentMode,
      cancelToken: token,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    res.when(
      success: (_) {
        _snack('Payment recorded.');
        Navigator.pop(context, true);
      },
      failure: (err) {
        final message = err is ApiException && err.message.trim().isNotEmpty
            ? err.message
            : "Couldn't save payment.";
        _snack(message);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final pad = AdaptiveUtils.getHorizontalPadding(w);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F7),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cs.onSurface.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(_submitting ? 'Saving...' : 'Save Payment'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              pad,
              topPadding + AppUtils.appBarHeightCustom + 28,
              pad,
              24,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.onSurface.withOpacity(0.12)),
              ),
              child: _loading
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        AppShimmer(width: 120, height: 14, radius: 8),
                        SizedBox(height: 12),
                        AppShimmer(width: double.infinity, height: 48, radius: 12),
                        SizedBox(height: 16),
                        AppShimmer(width: 120, height: 14, radius: 8),
                        SizedBox(height: 12),
                        AppShimmer(width: double.infinity, height: 48, radius: 12),
                        SizedBox(height: 16),
                        AppShimmer(width: 140, height: 14, radius: 8),
                        SizedBox(height: 12),
                        AppShimmer(width: double.infinity, height: 48, radius: 12),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _selectField(
                          label: 'Customer*',
                          value: _selectedUser == null
                              ? ''
                              : _userLabel(_selectedUser!),
                          hint: 'Select user',
                          onTap: () async {
                            final picked = await _showOptionSheet<AdminUserListItem>(
                              title: 'Select User',
                              items: _users,
                              labelFor: _userLabel,
                            );
                            if (!mounted || picked == null) return;
                            setState(() => _selectedUser = picked);
                          },
                        ),
                        const SizedBox(height: 16),
                        _selectField(
                          label: 'Vehicles*',
                          value: _selectedVehicleIds.isEmpty
                              ? ''
                              : '${_selectedVehicleIds.length} selected',
                          hint: 'Select vehicles',
                          onTap: _openVehiclesSheet,
                        ),
                        const SizedBox(height: 16),
                        _selectField(
                          label: 'Payment Mode*',
                          value: _paymentMode,
                          hint: 'Select payment mode',
                          onTap: () async {
                            final picked = await _showOptionSheet<String>(
                              title: 'Select Payment Mode',
                              items: _paymentModes,
                              labelFor: (item) => item,
                            );
                            if (!mounted || picked == null) return;
                            setState(() => _paymentMode = picked);
                          },
                        ),
                      ],
                    ),
            ),
          ),
          Positioned(
            left: pad,
            right: pad,
            top: 0,
            child: const AdminHomeAppBar(
              title: 'Add Payment',
              leadingIcon: Icons.payments_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectField({
    required String label,
    required String value,
    required String hint,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final fs = AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fs,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.onSurface.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value.isEmpty ? hint : value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fs,
                      fontWeight: FontWeight.w500,
                      color:
                          value.isEmpty ? cs.onSurface.withOpacity(0.6) : cs.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
