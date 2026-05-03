import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/device_type_option.dart';
import 'package:fleet_stack/core/models/sim_provider_option.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_devices_repository.dart';
import 'package:fleet_stack/core/repositories/admin_simcards_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/admin/components/admin/navigate.dart';
import 'package:fleet_stack/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class InventoryAddScreen extends StatefulWidget {
  const InventoryAddScreen({super.key});

  @override
  State<InventoryAddScreen> createState() => _InventoryAddScreenState();
}

class _InventoryAddScreenState extends State<InventoryAddScreen> {
  static const List<String> _tabs = <String>['Device', 'Sim', 'Device & Sim'];
  String _selectedTab = 'Device';

  final _deviceFormKey = GlobalKey<FormState>();
  final _simFormKey = GlobalKey<FormState>();

  final TextEditingController _imeiController = TextEditingController();
  final TextEditingController _simNumberController = TextEditingController();
  final TextEditingController _imsiController = TextEditingController();
  final TextEditingController _iccidController = TextEditingController();

  ApiClient? _apiClient;
  AdminDevicesRepository? _devicesRepo;
  AdminSimCardsRepository? _simsRepo;
  CancelToken? _loadToken;
  CancelToken? _submitToken;

  List<DeviceTypeOption> _deviceTypes = const <DeviceTypeOption>[];
  List<SimProviderOption> _providers = const <SimProviderOption>[];
  String? _selectedDeviceTypeLabel;
  String? _selectedProviderLabel;

  bool _loadingRefs = false;
  bool _submitting = false;
  bool _errorShown = false;

  ApiClient _apiOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    return _apiClient!;
  }

  AdminDevicesRepository _devicesRepoOrCreate() {
    _devicesRepo ??= AdminDevicesRepository(api: _apiOrCreate());
    return _devicesRepo!;
  }

  AdminSimCardsRepository _simsRepoOrCreate() {
    _simsRepo ??= AdminSimCardsRepository(api: _apiOrCreate());
    return _simsRepo!;
  }

  @override
  void initState() {
    super.initState();
    _loadReferenceData();
  }

  @override
  void dispose() {
    _loadToken?.cancel('Inventory add disposed');
    _submitToken?.cancel('Inventory add disposed');
    _imeiController.dispose();
    _simNumberController.dispose();
    _imsiController.dispose();
    _iccidController.dispose();
    super.dispose();
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadReferenceData() async {
    _loadToken?.cancel('Reload refs');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loadingRefs = true);

    try {
      final typesRes = await _devicesRepoOrCreate().getDeviceTypes(
        cancelToken: token,
      );
      final providersRes = await _simsRepoOrCreate().getSimProviders(
        cancelToken: token,
      );
      if (!mounted) return;

      List<DeviceTypeOption> types = const <DeviceTypeOption>[];
      List<SimProviderOption> providers = const <SimProviderOption>[];
      Object? firstErr;

      typesRes.when(
        success: (items) => types = items,
        failure: (err) => firstErr ??= err,
      );
      providersRes.when(
        success: (items) => providers = items,
        failure: (err) => firstErr ??= err,
      );

      if (!mounted) return;
      setState(() {
        _deviceTypes = types;
        _providers = providers;
        if (_selectedDeviceTypeLabel == null &&
            _deviceTypeLabels.isNotEmpty) {
          _selectedDeviceTypeLabel = _deviceTypeLabels.first;
        }
        if (_selectedProviderLabel == null && _providerLabels.isNotEmpty) {
          _selectedProviderLabel = _providerLabels.first;
        }
        _loadingRefs = false;
        if (firstErr == null) _errorShown = false;
      });

      if (firstErr != null && !_isCancelled(firstErr!)) {
        _showErrorOnce("Couldn't load device/provider references.");
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _deviceTypes = const <DeviceTypeOption>[];
        _providers = const <SimProviderOption>[];
        _loadingRefs = false;
      });
      _showErrorOnce("Couldn't load device/provider references.");
    }
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
                        style: GoogleFonts.roboto(
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
                        style: GoogleFonts.roboto(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: GoogleFonts.roboto(
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
                                style: GoogleFonts.roboto(
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
    if (_submitting) return;
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

    _submitToken?.cancel('Replace device submit');
    final token = CancelToken();
    _submitToken = token;

    setState(() => _submitting = true);
    final res = await _devicesRepoOrCreate().addDevice(
      imei: _imeiController.text.trim(),
      deviceTypeId: typeId,
      cancelToken: token,
    );

    if (!mounted) return;
    setState(() => _submitting = false);
    res.when(
      success: (_) {
        _snack('Device created');
        Navigator.pop(context, true);
      },
      failure: (err) {
        final message =
            err is ApiException && err.message.trim().isNotEmpty
                ? err.message
                : "Couldn't create device.";
        _snack(message);
      },
    );
  }

  Future<void> _submitSim() async {
    if (_submitting) return;
    if (!(_simFormKey.currentState?.validate() ?? false)) return;

    final payload = <String, dynamic>{
      'simNumber': _simNumberController.text.trim(),
    };

    final providerLabel = (_selectedProviderLabel ?? '').trim();
    if (providerLabel.isNotEmpty) {
      final providerId = _providerIdFromLabel(providerLabel);
      if (providerId.isNotEmpty) {
        final parsed = int.tryParse(providerId);
        payload['providerId'] = parsed ?? providerId;
      }
    }

    final imsi = _imsiController.text.trim();
    final iccid = _iccidController.text.trim();
    if (imsi.isNotEmpty) payload['imsi'] = imsi;
    if (iccid.isNotEmpty) payload['iccid'] = iccid;

    _submitToken?.cancel('Replace sim submit');
    final token = CancelToken();
    _submitToken = token;

    setState(() => _submitting = true);
    final res = await _simsRepoOrCreate().addSimCard(payload, cancelToken: token);

    if (!mounted) return;
    setState(() => _submitting = false);
    res.when(
      success: (_) {
        _snack('SIM card created');
        Navigator.pop(context, true);
      },
      failure: (err) {
        final message =
            err is ApiException && err.message.trim().isNotEmpty
                ? err.message
                : "Couldn't create SIM card.";
        _snack(message);
      },
    );
  }

  Future<void> _submitDeviceAndSim() async {
    if (_submitting) return;
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

    _submitToken?.cancel('Replace device+sim submit');
    final token = CancelToken();
    _submitToken = token;

    final providerLabel = (_selectedProviderLabel ?? '').trim();
    final providerId = providerLabel.isEmpty
        ? ''
        : _providerIdFromLabel(providerLabel);

    setState(() => _submitting = true);
    final res = await _devicesRepoOrCreate().addDeviceAndSim(
      imei: _imeiController.text.trim(),
      deviceTypeId: typeId,
      simNumber: _simNumberController.text.trim(),
      providerId: providerId,
      imsi: _imsiController.text.trim(),
      iccid: _iccidController.text.trim(),
      cancelToken: token,
    );

    if (!mounted) return;
    setState(() => _submitting = false);
    res.when(
      success: (_) {
        _snack('Device and SIM created');
        Navigator.pop(context, true);
      },
      failure: (err) {
        final message =
            err is ApiException && err.message.trim().isNotEmpty
                ? err.message
                : "Couldn't create device and SIM.";
        _snack(message);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F7),
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
                      context.go('/admin/sims/add');
                      return;
                    }
                    setState(() => _selectedTab = tab);
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
        border: Border.all(color: cs.surfaceVariant),
      ),
      child: Form(
        key: _deviceFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Device',
              style: GoogleFonts.roboto(
                fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'IMEI + Device Type.',
              style: GoogleFonts.roboto(
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
              loading: _loadingRefs,
              onTap: () async {
                if (_loadingRefs) return;
                final picked = await _showOptionSheet<String>(
                  title: 'Select Device Type',
                  items: labels,
                  labelFor: (item) => item,
                );
                if (!mounted || picked == null) return;
                setState(() => _selectedDeviceTypeLabel = picked);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitDevice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _submitting
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
                        style: GoogleFonts.roboto(
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
        border: Border.all(color: cs.surfaceVariant),
      ),
      child: Form(
        key: _simFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Sim Card',
              style: GoogleFonts.roboto(
                fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'SIM No. plus optional identifiers.',
              style: GoogleFonts.roboto(
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
              loading: _loadingRefs,
              onTap: () async {
                if (_loadingRefs) return;
                final picked = await _showOptionSheet<String>(
                  title: 'Select Provider',
                  items: labels,
                  labelFor: (item) => item,
                );
                if (!mounted) return;
                setState(() => _selectedProviderLabel = picked);
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
                onPressed: _submitting ? null : _submitSim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _submitting
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
                        style: GoogleFonts.roboto(
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
        border: Border.all(color: cs.surfaceVariant),
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
                  style: GoogleFonts.roboto(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'IMEI + Device Type.',
                  style: GoogleFonts.roboto(
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
                  loading: _loadingRefs,
                  onTap: () async {
                    if (_loadingRefs) return;
                    final picked = await _showOptionSheet<String>(
                      title: 'Select Device Type',
                      items: typeLabels,
                      labelFor: (item) => item,
                    );
                    if (!mounted || picked == null) return;
                    setState(() => _selectedDeviceTypeLabel = picked);
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
                  style: GoogleFonts.roboto(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'SIM No. plus optional identifiers.',
                  style: GoogleFonts.roboto(
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
                  loading: _loadingRefs,
                  onTap: () async {
                    if (_loadingRefs) return;
                    final picked = await _showOptionSheet<String>(
                      title: 'Select Provider',
                      items: providerLabels,
                      labelFor: (item) => item,
                    );
                    if (!mounted) return;
                    setState(() => _selectedProviderLabel = picked);
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
                  style: GoogleFonts.roboto(
                    fontSize: AdaptiveUtils.getTitleFontSize(w),
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'In "Device & Sim", the SIM will be linked to the Device IMEI you enter above.',
                  style: GoogleFonts.roboto(
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
              onPressed: _submitting ? null : _submitDeviceAndSim,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _submitting
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
                      style: GoogleFonts.roboto(
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
          style: GoogleFonts.roboto(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          validator: validator,
          style: GoogleFonts.roboto(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.roboto(
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
          style: GoogleFonts.roboto(
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
                    style: GoogleFonts.roboto(
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
