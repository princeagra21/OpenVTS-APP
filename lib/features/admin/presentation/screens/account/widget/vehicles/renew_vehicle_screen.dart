import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_linked_vehicle.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_account_error_presenter.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/features/admin/presentation/components/appbars/admin_home_appbar.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/admin/di/admin_account_providers.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class RenewVehicleScreen extends ConsumerStatefulWidget {
  final String? initialUserId;

  const RenewVehicleScreen({super.key, this.initialUserId});

  @override
  ConsumerState<RenewVehicleScreen> createState() => _RenewVehicleScreenState();
}

class _RenewVehicleScreenState extends ConsumerState<RenewVehicleScreen> {
  static const List<String> _paymentModes = <String>[
    'BANK_TRANSFER',
    'CASH',
    'UPI',
    'CARD',
    'CHEQUE',
    'OTHER',
  ];
  late final _usersRepo = ref.read(adminAccountCommandControllerProvider);

  List<AdminUserListItem> _users = const <AdminUserListItem>[];
  List<AdminLinkedVehicle> _vehicles = const <AdminLinkedVehicle>[];
  AdminUserListItem? _selectedUser;
  final Set<int> _selectedVehicleIds = <int>{};
  String _paymentMode = 'BANK_TRANSFER';
  final TextEditingController _amountController = TextEditingController();

  bool _loading = true;
  bool _loadingVehicles = false;
  bool _submitting = false;


  @override
  void initState() {
    super.initState();
    _loadInitialData();
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

  String _userLabel(AdminUserListItem item) {
    final name = item.fullName.trim();
    final username = item.username.trim();
    if (username.isEmpty) return name;
    return '$name (@$username)';
  }

  Future<void> _loadInitialData() async {
    updateLocalUiState(this, () => _loading = true);

    try {
      final usersRes = await _usersRepo.getUsers(
        page: 1,
        limit: 500,
      );

      List<AdminUserListItem> users = const <AdminUserListItem>[];
      usersRes.when(success: (d) => users = d, failure: (_) {});

      if (!mounted) return;
      updateLocalUiState(this, () {
        _users = users;
        if (widget.initialUserId != null) {
          _selectedUser = _users.where((u) => u.id == widget.initialUserId).firstOrNull;
        }
        _loading = false;
      });

      if (_selectedUser != null) {
        await _loadUserVehicles(_selectedUser!.id);
      }
    } catch (_) {
      if (!mounted) return;
      updateLocalUiState(this, () => _loading = false);
      _snack("Couldn't load users.");
    }
  }

  Future<void> _loadUserVehicles(String userId) async {
    updateLocalUiState(this, () {
      _loadingVehicles = true;
      _vehicles = const [];
      _selectedVehicleIds.clear();
      _amountController.text = '0';
    });

    final res = await _usersRepo.getLinkedVehicles(
      userId: userId,
    );

    if (!mounted) return;
    updateLocalUiState(this, () => _loadingVehicles = false);

    res.when(
      success: (items) {
        updateLocalUiState(this, () => _vehicles = items);
      },
      failure: (err) {
        _snack("Couldn't load linked vehicles.");
      },
    );
  }

  void _updateAmount() {
    double total = 0;
    for (final id in _selectedVehicleIds) {
      final v = _vehicles.where((e) => e.id == id).firstOrNull;
      if (v != null && v.plan != null) {
        total += v.plan!.price;
      }
    }
    _amountController.text = total.toStringAsFixed(2);
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
      _snack('Please select a customer first.');
      return;
    }
    if (_loadingVehicles) return;
    if (_vehicles.isEmpty) {
      _snack('No linked vehicles found for this customer.');
      return;
    }

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
                final t = '${v.name} ${v.plateNumber} ${v.imei ?? ''}'.toLowerCase();
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
                          final id = v.id;
                          final checked = _selectedVehicleIds.contains(id);
                          final planInfo = v.plan != null ? ' (${v.plan!.name}: ${v.plan!.price} ${v.plan!.currency})' : '';
                          return CheckboxListTile(
                            value: checked,
                            onChanged: (_) {
                              updateLocalUiState(this, () {
                                if (checked) {
                                  _selectedVehicleIds.remove(id);
                                } else {
                                  _selectedVehicleIds.add(id);
                                }
                                _updateAmount();
                              });
                              setSheetState(() {});
                            },
                            title: Text(v.name.isNotEmpty ? v.name : v.plateNumber),
                            subtitle: Text('${v.plateNumber}$planInfo'),
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
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      _snack('Please enter a valid amount.');
      return;
    }

    updateLocalUiState(this, () => _submitting = true);
    final res = await _usersRepo.renewVehicles(
      userId: _selectedUser!.id,
      vehicleIds: _selectedVehicleIds.toList(),
      paymentMode: _paymentMode,
      amount: amount,
    );
    if (!mounted) return;
    updateLocalUiState(this, () => _submitting = false);
    res.when(
      success: (_) {
        _snack('Vehicles renewed successfully.');
        Navigator.pop(context, true);
      },
      failure: (err) {
        final message = adminAccountIsKnownFailure(err) && adminAccountErrorMessage(err).trim().isNotEmpty
            ? adminAccountErrorMessage(err)
            : "Couldn't renew vehicles.";
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
                    onPressed: (_submitting || _loading || _selectedUser == null || _selectedVehicleIds.isEmpty) ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(_submitting ? 'Processing...' : 'Save Renewal'),
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
                          onTap: widget.initialUserId != null ? null : () async {
                            final picked = await _showOptionSheet<AdminUserListItem>(
                              title: 'Select User',
                              items: _users,
                              labelFor: _userLabel,
                            );
                            if (!mounted || picked == null) return;
                            updateLocalUiState(this, () => _selectedUser = picked);
                            _loadUserVehicles(picked.id);
                          },
                        ),
                        const SizedBox(height: 16),
                        _selectField(
                          label: 'Vehicles*',
                          value: _loadingVehicles
                              ? 'Loading vehicles...'
                              : (_selectedVehicleIds.isEmpty
                                  ? ''
                                  : '${_selectedVehicleIds.length} selected'),
                          hint: 'Select vehicles',
                          onTap: _openVehiclesSheet,
                        ),
                        const SizedBox(height: 16),
                        _inputField(
                          label: 'Amount*',
                          controller: _amountController,
                          hint: '0.00',
                          keyboardType: TextInputType.number,
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
              title: 'Renew Vehicle',
              leadingIcon: Icons.autorenew,
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
    VoidCallback? onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final fs = AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width);
    final isDisabled = onTap == null;

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
              color: isDisabled ? cs.onSurface.withOpacity(0.04) : null,
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
                if (!isDisabled)
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
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
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
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: fs,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: cs.onSurface.withOpacity(0.6),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}


