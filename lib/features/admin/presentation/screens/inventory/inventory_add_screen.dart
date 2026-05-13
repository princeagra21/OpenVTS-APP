import 'package:open_vts/features/vehicles/domain/entities/device_type_option.dart';
import 'package:open_vts/features/vehicles/domain/entities/sim_provider_option.dart';
import 'package:open_vts/features/admin/presentation/components/admin/navigate.dart';
import 'package:open_vts/features/admin/presentation/components/appbars/admin_home_appbar.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_mutation_input.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_device_form_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';
import 'package:open_vts/core/router/route_names.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class InventoryAddScreen extends ConsumerStatefulWidget {
  const InventoryAddScreen({super.key});

  @override
  ConsumerState<InventoryAddScreen> createState() => _InventoryAddScreenState();
}

class _InventoryAddScreenState extends ConsumerState<InventoryAddScreen> {
  static const List<String> _tabs = <String>['Device', 'Sim', 'Device & Sim'];
  String _selectedTab = 'Device';

  final _deviceFormKey = GlobalKey<FormState>();
  final _simFormKey = GlobalKey<FormState>();

  final TextEditingController _imeiController = TextEditingController();
  final TextEditingController _simNumberController = TextEditingController();
  final TextEditingController _imsiController = TextEditingController();
  final TextEditingController _iccidController = TextEditingController();
  List<DeviceTypeOption> _deviceTypes = const <DeviceTypeOption>[];
  List<SimProviderOption> _providers = const <SimProviderOption>[];
  String? _selectedDeviceTypeLabel;
  String? _selectedProviderLabel;

  bool _errorShown = false;



  @override
  void initState() {
    super.initState();
    _loadReferenceData();
  }

  @override
  void dispose() {
    _imeiController.dispose();
    _simNumberController.dispose();
    _imsiController.dispose();
    _iccidController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadReferenceData() async {
    await ref.read(adminDeviceFormControllerProvider.notifier).loadReferences();
    if (!mounted) return;
    final formState = ref.read(adminDeviceFormControllerProvider);
    updateLocalUiState(this, () {
      _deviceTypes = formState.deviceTypes;
      _providers = formState.providers;
      if (_selectedDeviceTypeLabel == null && _deviceTypeLabels.isNotEmpty) {
        _selectedDeviceTypeLabel = _deviceTypeLabels.first;
      }
      if (_selectedProviderLabel == null && _providerLabels.isNotEmpty) {
        _selectedProviderLabel = _providerLabels.first;
      }
      if (formState.errorMessage == null) _errorShown = false;
    });
    final error = formState.errorMessage;
    if (error != null) _showErrorOnce(error);
  }

  void _showErrorOnce(String message) {
    if (_errorShown || !mounted) return;
    _errorShown = true;
    _snack(message);
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

  List<String> get _providerLabels {
    final labels = _providers
        .map((e) => e.name.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    labels.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return labels;
  }

  String _deviceTypeIdFromLabel(String label) {
    final match = _deviceTypes.where((e) => e.name.trim() == label).toList();
    if (match.isEmpty) return '';
    return match.first.id.trim();
  }

  String _providerIdFromLabel(String label) {
    final match = _providers.where((e) => e.name.trim() == label).toList();
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
                        onChanged: (value) =>
                            setSheetState(() => query = value.trim()),
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

  Future<void> _submitDevice() async {
    if (ref.read(adminDeviceFormControllerProvider).isSubmitting) return;
    if (!(_deviceFormKey.currentState?.validate() ?? false)) return;

    final label = (_selectedDeviceTypeLabel ?? '').trim();
    if (label.isEmpty) {
      _snack('Select device type.');
      return;
    }
    final typeId = _deviceTypeIdFromLabel(label);
    if (typeId.isEmpty) {
      _snack('Selected device type is invalid.');
      return;
    }

    final ok = await ref.read(adminDeviceFormControllerProvider.notifier).createDevice(
          CreateAdminDeviceMutationInput(
            imei: _imeiController.text.trim(),
            deviceTypeId: typeId,
          ),
        );
    if (!mounted) return;
    if (ok) {
      _snack('Device created');
      Navigator.pop(context, true);
    } else {
      _snack(ref.read(adminDeviceFormControllerProvider).errorMessage ?? "Couldn't create device.");
    }
  }

  Future<void> _submitSim() async {
    if (ref.read(adminDeviceFormControllerProvider).isSubmitting) return;
    if (!(_simFormKey.currentState?.validate() ?? false)) return;

    final providerLabel = (_selectedProviderLabel ?? '').trim();
    final providerId = providerLabel.isEmpty ? '' : _providerIdFromLabel(providerLabel);

    final ok = await ref.read(adminDeviceFormControllerProvider.notifier).createSimCard(
          CreateAdminSimCardMutationInput(
            simNumber: _simNumberController.text.trim(),
            providerId: providerId,
            imsi: _imsiController.text.trim(),
            iccid: _iccidController.text.trim(),
          ),
        );
    if (!mounted) return;
    if (ok) {
      _snack('SIM card created');
      Navigator.pop(context, true);
    } else {
      _snack(ref.read(adminDeviceFormControllerProvider).errorMessage ?? "Couldn't create SIM card.");
    }
  }

  Future<void> _submitDeviceAndSim() async {
    if (ref.read(adminDeviceFormControllerProvider).isSubmitting) return;
    if (!(_deviceFormKey.currentState?.validate() ?? false)) return;
    if (!(_simFormKey.currentState?.validate() ?? false)) return;

    final label = (_selectedDeviceTypeLabel ?? '').trim();
    if (label.isEmpty) {
      _snack('Select device type.');
      return;
    }
    final typeId = _deviceTypeIdFromLabel(label);
    if (typeId.isEmpty) {
      _snack('Selected device type is invalid.');
      return;
    }

    final providerLabel = (_selectedProviderLabel ?? '').trim();
    final providerId = providerLabel.isEmpty ? '' : _providerIdFromLabel(providerLabel);

    final ok = await ref.read(adminDeviceFormControllerProvider.notifier).createDeviceAndSim(
          CreateAdminDeviceAndSimMutationInput(
            imei: _imeiController.text.trim(),
            deviceTypeId: typeId,
            simNumber: _simNumberController.text.trim(),
            providerId: providerId,
            imsi: _imsiController.text.trim(),
            iccid: _iccidController.text.trim(),
          ),
        );
    if (!mounted) return;
    if (ok) {
      _snack('Device and SIM created');
      Navigator.pop(context, true);
    } else {
      _snack(ref.read(adminDeviceFormControllerProvider).errorMessage ?? "Couldn't create device and SIM.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(adminDeviceFormControllerProvider);
    final isSubmitting = formState.isSubmitting;
    final isLoadingRefs = formState.isLoadingRefs;
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    final horizontalPadding = AdaptiveUtils.isVerySmallScreen(screenWidth)
        ? 8.0
        : AdaptiveUtils.isSmallScreen(screenWidth)
            ? 10.0
            : 12.0;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? OpenVtsColors.panelDark
          : OpenVtsColors.panelLight,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding + AppUtils.appBarHeightCustom + 28,
              horizontalPadding,
              84,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NavigateBox(
                  selectedTab: _selectedTab,
                  tabs: _tabs,
                  title: 'Add Inventory',
                  subtitle: 'Create Device or SIM card.',
                  onTabSelected: (tab) {
                    if (tab == 'Sim') {
                      context.go(AppRoutePaths.adminSimsAdd);
                      return;
                    }
                    updateLocalUiState(this, () => _selectedTab = tab);
                  },
                ),
                const SizedBox(height: 4),
                _selectedTab == 'Device'
                    ? _buildDeviceTab(colorScheme, screenWidth)
                    : _selectedTab == 'Device & Sim'
                    ? _buildDeviceAndSimTab(colorScheme, screenWidth)
                    : _buildSimTab(colorScheme, screenWidth),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            top: 0,
            child: AdminHomeAppBar(
              title: 'Add Inventory',
              leadingIcon: Symbols.inventory_2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTab(ColorScheme cs, double w) {
    final formState = ref.watch(adminDeviceFormControllerProvider);
    final isSubmitting = formState.isSubmitting;
    final isLoadingRefs = formState.isLoadingRefs;
    final labels = _deviceTypeLabels;
    if (_selectedDeviceTypeLabel != null &&
        !labels.contains(_selectedDeviceTypeLabel)) {
      _selectedDeviceTypeLabel = null;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.surfaceContainerHighest),
      ),
      child: Form(
        key: _deviceFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Device',
              style: AppFonts.roboto(
                fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'IMEI + Device Type.',
              style: AppFonts.roboto(
                fontSize: AdaptiveUtils.getTitleFontSize(w) - 2,
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            _InputField(
              label: 'IMEI*',
              hint: '356938035643809',
              controller: _imeiController,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _SelectField(
              label: 'Device Type*',
              value: _selectedDeviceTypeLabel ?? '',
              hint: 'Select device type',
              loading: isLoadingRefs,
              onTap: () async {
                if (isLoadingRefs) return;
                final picked = await _showOptionSheet<String>(
                  title: 'Select Device Type',
                  items: labels,
                  labelFor: (item) => item,
                );
                if (!mounted || picked == null) return;
                updateLocalUiState(this, () => _selectedDeviceTypeLabel = picked);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submitDevice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isSubmitting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(cs.onPrimary),
                        ),
                      )
                    : Text(
                        'Create Device',
                        style: AppFonts.roboto(
                          fontSize: AdaptiveUtils.getTitleFontSize(w),
                          fontWeight: FontWeight.w600,
                          color: cs.onPrimary,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimTab(ColorScheme cs, double w) {
    final formState = ref.watch(adminDeviceFormControllerProvider);
    final isSubmitting = formState.isSubmitting;
    final isLoadingRefs = formState.isLoadingRefs;
    final labels = _providerLabels;
    if (_selectedProviderLabel != null &&
        !labels.contains(_selectedProviderLabel)) {
      _selectedProviderLabel = null;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.surfaceContainerHighest),
      ),
      child: Form(
        key: _simFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Sim Card',
              style: AppFonts.roboto(
                fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'SIM No. plus optional identifiers.',
              style: AppFonts.roboto(
                fontSize: AdaptiveUtils.getTitleFontSize(w) - 2,
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            _InputField(
              label: 'Sim No.*',
              hint: '+971501234567',
              controller: _simNumberController,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _SelectField(
              label: 'Sim Provider',
              value: _selectedProviderLabel ?? '',
              hint: 'Select provider (optional)',
              loading: isLoadingRefs,
              onTap: () async {
                if (isLoadingRefs) return;
                final picked = await _showOptionSheet<String>(
                  title: 'Select Provider',
                  items: labels,
                  labelFor: (item) => item,
                );
                if (!mounted) return;
                updateLocalUiState(this, () => _selectedProviderLabel = picked);
              },
            ),
            const SizedBox(height: 16),
            _InputField(
              label: 'IMSI',
              hint: '(optional)',
              controller: _imsiController,
            ),
            const SizedBox(height: 16),
            _InputField(
              label: 'ICCID',
              hint: '(optional)',
              controller: _iccidController,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submitSim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isSubmitting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(cs.onPrimary),
                        ),
                      )
                    : Text(
                        'Create Sim Card',
                        style: AppFonts.roboto(
                          fontSize: AdaptiveUtils.getTitleFontSize(w),
                          fontWeight: FontWeight.w600,
                          color: cs.onPrimary,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceAndSimTab(ColorScheme cs, double w) {
    final formState = ref.watch(adminDeviceFormControllerProvider);
    final isSubmitting = formState.isSubmitting;
    final isLoadingRefs = formState.isLoadingRefs;
    final typeLabels = _deviceTypeLabels;
    final providerLabels = _providerLabels;
    if (_selectedDeviceTypeLabel != null &&
        !typeLabels.contains(_selectedDeviceTypeLabel)) {
      _selectedDeviceTypeLabel = null;
    }
    if (_selectedProviderLabel != null &&
        !providerLabels.contains(_selectedProviderLabel)) {
      _selectedProviderLabel = null;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Form(
            key: _deviceFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Device',
                  style: AppFonts.roboto(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'IMEI + Device Type.',
                  style: AppFonts.roboto(
                    fontSize: AdaptiveUtils.getTitleFontSize(w) - 2,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                _InputField(
                  label: 'IMEI*',
                  hint: '356938035643809',
                  controller: _imeiController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _SelectField(
                  label: 'Device Type*',
                  value: _selectedDeviceTypeLabel ?? '',
                  hint: 'Select device type',
                  loading: isLoadingRefs,
                  onTap: () async {
                    if (isLoadingRefs) return;
                    final picked = await _showOptionSheet<String>(
                      title: 'Select Device Type',
                      items: typeLabels,
                      labelFor: (item) => item,
                    );
                    if (!mounted || picked == null) return;
                    updateLocalUiState(this, () => _selectedDeviceTypeLabel = picked);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Form(
            key: _simFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Sim Card',
                  style: AppFonts.roboto(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'SIM No. plus optional identifiers.',
                  style: AppFonts.roboto(
                    fontSize: AdaptiveUtils.getTitleFontSize(w) - 2,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                _InputField(
                  label: 'Sim No.*',
                  hint: '+971501234567',
                  controller: _simNumberController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _SelectField(
                  label: 'Sim Provider',
                  value: _selectedProviderLabel ?? '',
                  hint: 'Select provider (optional)',
                  loading: isLoadingRefs,
                  onTap: () async {
                    if (isLoadingRefs) return;
                    final picked = await _showOptionSheet<String>(
                      title: 'Select Provider',
                      items: providerLabels,
                      labelFor: (item) => item,
                    );
                    if (!mounted) return;
                    updateLocalUiState(this, () => _selectedProviderLabel = picked);
                  },
                ),
                const SizedBox(height: 16),
                _InputField(
                  label: 'IMSI',
                  hint: '(optional)',
                  controller: _imsiController,
                ),
                const SizedBox(height: 16),
                _InputField(
                  label: 'ICCID',
                  hint: '(optional)',
                  controller: _iccidController,
                ),
                const SizedBox(height: 12),
                Text(
                  'Linking',
                  style: AppFonts.roboto(
                    fontSize: AdaptiveUtils.getTitleFontSize(w),
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'In "Device & Sim", the SIM will be linked to the Device IMEI you enter above.',
                  style: AppFonts.roboto(
                    fontSize: AdaptiveUtils.getTitleFontSize(w) - 2,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : _submitDeviceAndSim,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isSubmitting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(cs.onPrimary),
                      ),
                    )
                  : Text(
                      'Create Device & Sim',
                      style: AppFonts.roboto(
                        fontSize: AdaptiveUtils.getTitleFontSize(w),
                        fontWeight: FontWeight.w600,
                        color: cs.onPrimary,
                      ),
                    ),
            ),
          ),
        ],
      ),
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
    final double fontSize = AdaptiveUtils.getTitleFontSize(
      MediaQuery.of(context).size.width,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.roboto(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          validator: validator,
          style: AppFonts.roboto(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.error, width: 1.2),
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
  final bool loading;
  final VoidCallback onTap;

  const _SelectField({
    required this.label,
    required this.value,
    required this.hint,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double fontSize = AdaptiveUtils.getTitleFontSize(
      MediaQuery.of(context).size.width,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.roboto(
            fontSize: fontSize,
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
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.onSurface.withOpacity(0.12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value.isEmpty ? hint : value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.roboto(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: value.isEmpty
                          ? cs.onSurface.withOpacity(0.6)
                          : cs.onSurface,
                    ),
                  ),
                ),
                if (loading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  )
                else
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


