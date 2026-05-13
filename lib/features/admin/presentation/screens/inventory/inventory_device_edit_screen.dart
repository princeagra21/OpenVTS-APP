import 'package:open_vts/features/admin/domain/entities/admin_device_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_mutation_input.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_device_detail_controller.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_device_form_controller.dart';
import 'package:open_vts/features/vehicles/domain/entities/device_type_option.dart';
import 'package:open_vts/features/vehicles/domain/entities/sim_option.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/features/admin/presentation/components/appbars/admin_home_appbar.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class InventoryDeviceEditScreen extends ConsumerStatefulWidget {
  final String deviceId;
  final AdminDeviceListItem? initialDevice;

  const InventoryDeviceEditScreen({
    super.key,
    required this.deviceId,
    this.initialDevice,
  });

  @override
  ConsumerState<InventoryDeviceEditScreen> createState() => _InventoryDeviceEditScreenState();
}

class _InventoryDeviceEditScreenState extends ConsumerState<InventoryDeviceEditScreen> {
  static const String _unassignedValue = '__unassigned__';

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _imeiController = TextEditingController();

  List<DeviceTypeOption> _deviceTypes = const <DeviceTypeOption>[];
  List<SimOption> _quickSims = const <SimOption>[];

  String? _selectedDeviceTypeLabel;
  String? _selectedSimLabel;
  String _selectedStatus = 'IN_STOCK';
  bool _isActive = true;
  bool _loadedIntoForm = false;
  String _currentSimText = '—';
  String _initialImei = '';
  String _initialDeviceTypeLabel = '';
  String _initialSimLabel = 'Unassigned';
  String _initialStatus = 'IN_STOCK';
  bool _initialIsActive = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminDeviceFormControllerProvider.notifier).loadReferences(quickSims: true);
    });
  }

  @override
  void dispose() {
    _imeiController.dispose();
    super.dispose();
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _statusToLabel(String value) {
    switch (value.toUpperCase()) {
      case 'IN_USE':
        return 'In Use';
      case 'IN_STOCK':
        return 'In Stock';
      case 'MAINTENANCE':
        return 'Maintenance';
      case 'INACTIVE':
        return 'Inactive';
      default:
        return value;
    }
  }

  String _normalizeStatus(Object? value) {
    final raw = (value ?? '').toString().trim().toUpperCase();
    if (raw == 'ACTIVE' || raw == 'ENABLED') return 'IN_USE';
    if (raw == 'IN_USE' || raw == 'IN_STOCK') return raw;
    return 'IN_STOCK';
  }

  List<String> get _deviceTypeLabels {
    final labels = _deviceTypes
        .map((e) => e.name.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    labels.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return labels;
  }

  List<String> get _simLabels {
    final labels = <String>['Unassigned'];
    for (final sim in _quickSims) {
      final n = sim.number.trim();
      if (n.isNotEmpty) labels.add(n);
    }
    final selected = (_selectedSimLabel ?? '').trim();
    if (selected.isNotEmpty && selected.toLowerCase() != 'unassigned') {
      labels.add(selected);
    }
    return labels.toSet().toList();
  }

  String _deviceTypeIdByLabel(String label) {
    final match = _deviceTypes.where((e) => e.name.trim() == label).toList();
    if (match.isEmpty) return '';
    return match.first.id.trim();
  }

  String _simIdByLabel(String label) {
    if (label == 'Unassigned') return _unassignedValue;
    final match = _quickSims.where((e) => e.number.trim() == label).toList();
    if (match.isEmpty) return '';
    return match.first.id.trim();
  }

  Future<T?> _showOptionSheet<T>({
    required String title,
    required List<T> items,
    required String Function(T item) labelFor,
  }) {
    final cs = Theme.of(context).colorScheme;
    final searchController = TextEditingController();
    String query = '';
    final double fontSize = AdaptiveUtils.getTitleFontSize(
      MediaQuery.of(context).size.width,
    );

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.7,
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                final filtered = items.where((item) {
                  final text = labelFor(item).toLowerCase();
                  return text.contains(query.toLowerCase());
                }).toList();
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppFonts.roboto(
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        onChanged: (value) => setSheetState(() => query = value.trim()),
                        style: AppFonts.roboto(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: AppFonts.roboto(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface.withOpacity(0.6),
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: cs.onSurface.withOpacity(0.6),
                            size: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: cs.onSurface.withOpacity(0.12),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: cs.onSurface.withOpacity(0.12),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: cs.primary, width: 1.2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, index) {
                            final item = filtered[index];
                            return ListTile(
                              title: Text(
                                labelFor(item),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.roboto(
                                  fontSize: 14,
                                  height: 20 / 14,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
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
        );
      },
    );
  }

  void _applyLoadedData(AdminDeviceListItem item, AdminDeviceFormState formState) {
    if (_loadedIntoForm) return;
    final imei = item.imei.trim();
    final typeName = item.typeName == '—' ? '' : item.typeName.trim();
    final rawSimNumber = item.simNumber.trim();
    final simNumber = rawSimNumber.toLowerCase() == 'no sim' ? '' : rawSimNumber;
    final resolvedType = typeName.isNotEmpty
        ? typeName
        : (_deviceTypeLabels.isNotEmpty ? _deviceTypeLabels.first : null);
    final resolvedSim = simNumber.isNotEmpty ? simNumber : 'Unassigned';
    updateLocalUiState(this, () {
      _deviceTypes = formState.deviceTypes;
      _quickSims = formState.sims;
      _imeiController.text = imei;
      _selectedDeviceTypeLabel = resolvedType;
      _selectedSimLabel = resolvedSim;
      _currentSimText = simNumber.isNotEmpty ? simNumber : '—';
      _isActive = item.isActive;
      _selectedStatus = _normalizeStatus(item.rawStatus);
      _initialImei = imei;
      _initialDeviceTypeLabel = resolvedType ?? '';
      _initialSimLabel = resolvedSim;
      _initialStatus = _normalizeStatus(item.rawStatus);
      _initialIsActive = item.isActive;
      _loadedIntoForm = true;
    });
  }

  Future<void> _save() async {
    final formState = ref.read(adminDeviceFormControllerProvider);
    if (formState.isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final imei = _imeiController.text.trim();
    if (imei.isEmpty) {
      _snack('IMEI is required.');
      return;
    }

    final typeLabel = (_selectedDeviceTypeLabel ?? '').trim();
    final simLabel = (_selectedSimLabel ?? '').trim();

    if (typeLabel.isEmpty) {
      _snack('Select device type.');
      return;
    }

    final typeId = _deviceTypeIdByLabel(typeLabel);
    final simId = _simIdByLabel(simLabel);
    if (typeId.isEmpty) {
      _snack('Invalid device type.');
      return;
    }
    if (simLabel.isNotEmpty && simId.isEmpty) {
      _snack('Invalid SIM.');
      return;
    }

    final hasChanges = imei != _initialImei ||
        typeLabel != _initialDeviceTypeLabel ||
        _selectedStatus != _initialStatus ||
        _isActive != _initialIsActive ||
        simLabel != _initialSimLabel;

    if (!hasChanges) {
      _snack('No changes to update.');
      return;
    }

    final ok = await ref.read(adminDeviceFormControllerProvider.notifier).updateDevice(
          widget.deviceId,
          UpdateAdminDeviceMutationInput(
            imei: imei != _initialImei ? imei : null,
            deviceTypeId: typeLabel != _initialDeviceTypeLabel ? typeId : null,
            status: _selectedStatus != _initialStatus ? _selectedStatus : null,
            isActive: _isActive != _initialIsActive ? _isActive : null,
            simId: simLabel != _initialSimLabel && simId != _unassignedValue ? simId : null,
            clearSim: simLabel != _initialSimLabel && simId == _unassignedValue,
          ),
        );
    if (!mounted) return;
    if (ok) {
      _snack('Device updated.');
      Navigator.pop(context, true);
    } else {
      final message = ref.read(adminDeviceFormControllerProvider).errorMessage?.trim();
      _snack(message == null || message.isEmpty ? "Couldn't update device." : message);
    }
  }

  Widget _buildLoadingSkeleton(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          AppShimmer(width: 120, height: 14, radius: 8),
          SizedBox(height: 12),
          AppShimmer(width: double.infinity, height: 48, radius: 12),
          SizedBox(height: 16),
          AppShimmer(width: 140, height: 14, radius: 8),
          SizedBox(height: 12),
          AppShimmer(width: double.infinity, height: 48, radius: 12),
          SizedBox(height: 16),
          AppShimmer(width: 130, height: 14, radius: 8),
          SizedBox(height: 12),
          AppShimmer(width: double.infinity, height: 48, radius: 12),
          SizedBox(height: 16),
          AppShimmer(width: 100, height: 14, radius: 8),
          SizedBox(height: 12),
          AppShimmer(width: double.infinity, height: 48, radius: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    final detailState = ref.watch(adminDeviceDetailControllerProvider(widget.deviceId));
    final formState = ref.watch(adminDeviceFormControllerProvider);
    final device = detailState.detail ?? widget.initialDevice;
    final isLoading = detailState.isLoading || formState.isLoadingRefs || device == null || !_loadedIntoForm;
    final isSaving = formState.isSubmitting;
    final horizontalPadding = AdaptiveUtils.isVerySmallScreen(screenWidth)
        ? 8.0
        : AdaptiveUtils.isSmallScreen(screenWidth)
            ? 10.0
            : 12.0;

    if (!_loadedIntoForm && device != null && !formState.isLoadingRefs) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _applyLoadedData(device, formState);
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? OpenVtsColors.panelDark
          : OpenVtsColors.panelLight,
      bottomNavigationBar: isLoading
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: isSaving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: cs.onSurface.withOpacity(0.2)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppFonts.roboto(
                              fontSize: AdaptiveUtils.getTitleFontSize(screenWidth),
                              height: 20 / 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            isSaving ? 'Saving...' : 'Save',
                            style: AppFonts.roboto(
                              fontSize: AdaptiveUtils.getTitleFontSize(screenWidth),
                              height: 20 / 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onPrimary,
                            ),
                          ),
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
              horizontalPadding,
              topPadding + AppUtils.appBarHeightCustom + 28,
              horizontalPadding,
              isLoading ? 84 : 24,
            ),
            child: isLoading
                ? _buildLoadingSkeleton(cs)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cs.onSurface.withOpacity(0.12)),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _InputField(
                                label: 'IMEI*',
                                hint: 'Enter IMEI',
                                controller: _imeiController,
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              _ReadOnlyField(
                                label: 'Current SIM',
                                value: _currentSimText.isEmpty ? '—' : _currentSimText,
                              ),
                              const SizedBox(height: 16),
                              _SelectField(
                                label: 'Device Type*',
                                value: _selectedDeviceTypeLabel ?? '',
                                hint: 'Select device type',
                                onTap: () async {
                                  final picked = await _showOptionSheet<String>(
                                    title: 'Select Device Type',
                                    items: _deviceTypeLabels,
                                    labelFor: (item) => item,
                                  );
                                  if (!mounted || picked == null) return;
                                  updateLocalUiState(this, () => _selectedDeviceTypeLabel = picked);
                                },
                              ),
                              const SizedBox(height: 16),
                              _SelectField(
                                label: 'Sim Number',
                                value: _selectedSimLabel ?? '',
                                hint: 'Unassigned',
                                onTap: () async {
                                  final picked = await _showOptionSheet<String>(
                                    title: 'Select SIM',
                                    items: _simLabels,
                                    labelFor: (item) => item,
                                  );
                                  if (!mounted || picked == null) return;
                                  updateLocalUiState(this, () => _selectedSimLabel = picked);
                                },
                              ),
                              const SizedBox(height: 16),
                              _SelectField(
                                label: 'Status*',
                                value: _statusToLabel(_selectedStatus),
                                hint: 'In Stock',
                                onTap: () async {
                                  const statusValues = <String>[
                                    'IN_STOCK',
                                    'IN_USE',
                                  ];
                                  final picked = await _showOptionSheet<String>(
                                    title: 'Select Status',
                                    items: statusValues,
                                    labelFor: _statusToLabel,
                                  );
                                  if (!mounted || picked == null) return;
                                  updateLocalUiState(this, () => _selectedStatus = picked);
                                },
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
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
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Active',
                                            style: AppFonts.roboto(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Enable or disable this device.',
                                            style: AppFonts.roboto(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: cs.onSurface.withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: _isActive,
                                      onChanged: (v) => updateLocalUiState(this, () => _isActive = v),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            top: 0,
            child: const AdminHomeAppBar(
              title: 'Edit Device',
              leadingIcon: Symbols.inventory_2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fs = AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.roboto(
            fontSize: fs,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.onSurface.withOpacity(0.12)),
          ),
          child: Text(
            value.isEmpty ? '—' : value,
            style: AppFonts.roboto(
              fontSize: fs,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fs = AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.roboto(
            fontSize: fs,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          validator: validator,
          style: AppFonts.roboto(
            fontSize: fs,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppFonts.roboto(
              fontSize: fs,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withOpacity(0.6),
            ),
            filled: true,
            fillColor: Colors.transparent,
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
              borderSide: BorderSide(color: cs.primary, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectField extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final VoidCallback onTap;

  const _SelectField({
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fs = AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.roboto(
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
                    style: AppFonts.roboto(
                      fontSize: fs,
                      fontWeight: FontWeight.w500,
                      color: value.isEmpty
                          ? cs.onSurface.withOpacity(0.6)
                          : cs.onSurface,
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


