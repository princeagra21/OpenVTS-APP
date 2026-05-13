import 'package:open_vts/features/admin/domain/entities/admin_linked_vehicle.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_vehicle_preview_item.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/features/admin/presentation/components/appbars/admin_home_appbar.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/admin/di/admin_operations_providers.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class AddPaymentScreen extends ConsumerStatefulWidget {
  const AddPaymentScreen({super.key});

  @override
  ConsumerState<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends ConsumerState<AddPaymentScreen> {
  static const List<String> _paymentModes = <String>[
    'BANK_TRANSFER',
    'CASH',
    'UPI',
    'CARD',
    'CHEQUE',
    'OTHER',
  ];

  List<AdminUserListItem> _users = const <AdminUserListItem>[];
  List<AdminVehiclePreviewItem> _vehicles = const <AdminVehiclePreviewItem>[];
  AdminUserListItem? _selectedUser;
  final Set<String> _selectedVehicleIds = <String>{};
  String _paymentMode = 'BANK_TRANSFER';
  final TextEditingController _amountController = TextEditingController();

  bool _loading = true;
  bool _loadingLinkedVehicles = false;
  bool _submitting = false;
  VoidCallback? _refreshVehiclesSheet;




  @override
  void initState() {
    super.initState();
    _loadRefs();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  double _vehiclePlanPrice(AdminVehiclePreviewItem item) {
    final raw = item.raw;
    final plan = raw['plan'];
    if (plan is Map) {
      final price = plan['price'];
      if (price is num) return price.toDouble();
      final parsed = double.tryParse(price?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    final fallback = raw['planPrice'] ?? raw['price'] ?? raw['amount'];
    if (fallback is num) return fallback.toDouble();
    return double.tryParse(fallback?.toString() ?? '') ?? 0;
  }

  AdminVehiclePreviewItem _toPreview(AdminLinkedVehicle v) {
    return AdminVehiclePreviewItem(<String, dynamic>{
      'id': v.id,
      'name': v.name,
      'plateNumber': v.plateNumber,
      'imei': v.imei ?? '',
      'plan': v.plan == null
          ? null
          : <String, dynamic>{
              'id': v.plan!.id,
              'name': v.plan!.name,
              'price': v.plan!.price,
              'durationDays': v.plan!.durationDays,
              'currency': v.plan!.currency,
            },
    });
  }

  Future<void> _loadLinkedVehiclesForUser(String userId) async {
    updateLocalUiState(this, () => _loadingLinkedVehicles = true);
    _refreshVehiclesSheet?.call();

    final ok = await ref.read(adminPaymentsControllerProvider.notifier).loadLinkedVehicles(userId: userId);
    if (!mounted) return;
    final nextState = ref.read(adminPaymentsControllerProvider);

    updateLocalUiState(this, () {
      _vehicles = ok ? nextState.linkedVehicles.map(_toPreview).toList() : const <AdminVehiclePreviewItem>[];
      _selectedVehicleIds.clear();
      _amountController.clear();
      _loadingLinkedVehicles = false;
    });
    _refreshVehiclesSheet?.call();

    if (!ok && nextState.actionError != null) {
      _snack(nextState.actionError!.message);
    }
  }

  void _syncAmountFromSelectedVehicles() {
    if (_selectedVehicleIds.isEmpty) return;
    double total = 0;
    for (final vehicle in _vehicles) {
      if (_selectedVehicleIds.contains(vehicle.id.trim())) {
        total += _vehiclePlanPrice(vehicle);
      }
    }
    if (total <= 0) return;
    final hasFraction = total % 1 != 0;
    _amountController.text = hasFraction
        ? total.toStringAsFixed(2)
        : total.toStringAsFixed(0);
  }

  String _userLabel(AdminUserListItem item) {
    final name = item.fullName.trim();
    final username = item.username.trim();
    if (username.isEmpty) return name;
    return '$name (@$username)';
  }

  Future<void> _loadRefs() async {
    updateLocalUiState(this, () => _loading = true);

    final ok = await ref.read(adminPaymentsControllerProvider.notifier).loadUsers(search: null);
    if (!mounted) return;
    final nextState = ref.read(adminPaymentsControllerProvider);

    updateLocalUiState(this, () {
      _users = ok ? nextState.users : const <AdminUserListItem>[];
      _vehicles = const <AdminVehiclePreviewItem>[];
      _loading = false;
    });

    if (!ok) {
      _snack(nextState.actionError?.message ?? "Couldn't load users/vehicles.");
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
    if (_selectedUser == null) {
      _snack('Select user first.');
      return;
    }
    final cs = Theme.of(context).colorScheme;
    String query = '';
    final search = TextEditingController();
    final vehiclesSnapshot = List<AdminVehiclePreviewItem>.from(_vehicles);

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
              _refreshVehiclesSheet = () {
                if (mounted) setSheetState(() {});
              };
              final filtered = vehiclesSnapshot.where((v) {
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
                      child: _loadingLinkedVehicles
                          ? const Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(strokeWidth: 2.4),
                              ),
                            )
                          : filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.directions_car_outlined,
                                    size: 34,
                                    color: cs.onSurface.withOpacity(0.45),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No vehicles available',
                                    style: TextStyle(
                                      color: cs.onSurface.withOpacity(0.7),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Select a user with linked vehicles.',
                                    style: TextStyle(
                                      color: cs.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (_, i) {
                                final v = filtered[i];
                                final id = v.id.trim();
                                final checked = _selectedVehicleIds.contains(id);
                                return CheckboxListTile(
                                  value: checked,
                                  onChanged: (_) {
                                    if (checked) {
                                      _selectedVehicleIds.remove(id);
                                    } else {
                                      _selectedVehicleIds.add(id);
                                    }
                                    _syncAmountFromSelectedVehicles();
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
    _refreshVehiclesSheet = null;
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
    final amount = _amountController.text.trim();
    if (amount.isEmpty) {
      _snack('Enter amount.');
      return;
    }
    final parsedAmount = double.tryParse(amount);
    if (parsedAmount == null || parsedAmount <= 0) {
      _snack('Enter a valid amount.');
      return;
    }

    updateLocalUiState(this, () => _submitting = true);
    final ok = await ref.read(adminPaymentsControllerProvider.notifier).createPayment(
          userId: _selectedUser!.id,
          vehicleIds: _selectedVehicleIds.toList(),
          amount: amount,
          paymentMode: _paymentMode,
        );
    if (!mounted) return;
    final nextState = ref.read(adminPaymentsControllerProvider);
    updateLocalUiState(this, () => _submitting = false);
    if (ok) {
      _snack('Payment recorded.');
      Navigator.pop(context, true);
      return;
    }
    _snack(nextState.actionError?.message ?? "Couldn't save payment.");
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final pad = AdaptiveUtils.getHorizontalPadding(w);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? OpenVtsColors.panelDark
          : OpenVtsColors.panelLight,
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
                            updateLocalUiState(this, () => _selectedUser = picked);
                            await _loadLinkedVehiclesForUser(picked.id);
                          },
                        ),
                        const SizedBox(height: 16),
                        _selectField(
                          label: 'Vehicles*',
                          value: _selectedVehicleIds.isNotEmpty
                              ? '${_selectedVehicleIds.length} selected'
                              : _loadingLinkedVehicles
                              ? 'Loading vehicles...'
                              : '',
                          hint: 'Select vehicles',
                          onTap: _openVehiclesSheet,
                        ),
                        const SizedBox(height: 16),
                        _inputField(
                          label: 'Amount*',
                          hint: 'Enter renew amount',
                          controller: _amountController,
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
                            updateLocalUiState(this, () => _paymentMode = picked);
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

  Widget _inputField({
    required String label,
    required String hint,
    required TextEditingController controller,
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
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: fs,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withOpacity(0.6),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.onSurface.withOpacity(0.12)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.onSurface.withOpacity(0.12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.primary),
            ),
          ),
        ),
      ],
    );
  }
}


