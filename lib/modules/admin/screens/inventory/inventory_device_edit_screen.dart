import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/device_type_option.dart';
import 'package:fleet_stack/core/models/sim_option.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_devices_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class InventoryDeviceEditScreen extends StatefulWidget {
  final String deviceId;
  final Map<String, dynamic>? initialRaw;

  const InventoryDeviceEditScreen({
    super.key,
    required this.deviceId,
    this.initialRaw,
  });

  @override
  State<InventoryDeviceEditScreen> createState() => _InventoryDeviceEditScreenState();
}

class _InventoryDeviceEditScreenState extends State<InventoryDeviceEditScreen> {
  static const String _unassignedValue = '__unassigned__';

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _imeiController = TextEditingController();

  ApiClient? _apiClient;
  AdminDevicesRepository? _repo;
  CancelToken? _loadToken;
  CancelToken? _saveToken;

  List<DeviceTypeOption> _deviceTypes = const <DeviceTypeOption>[];
  List<SimOption> _quickSims = const <SimOption>[];

  String? _selectedDeviceTypeLabel;
  String? _selectedSimLabel;
  String _selectedStatus = 'IN_STOCK';
  bool _isActive = true;
  bool _loading = true;
  bool _saving = false;
  String _currentSimText = '—';
  String _initialImei = '';
  String _initialDeviceTypeLabel = '';
  String _initialSimLabel = 'Unassigned';
  String _initialStatus = 'IN_STOCK';
  bool _initialIsActive = true;

  ApiClient _apiOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    return _apiClient!;
  }

  AdminDevicesRepository _repoOrCreate() {
    _repo ??= AdminDevicesRepository(api: _apiOrCreate());
    return _repo!;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _loadToken?.cancel('Edit disposed');
    _saveToken?.cancel('Edit disposed');
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
                        onChanged: (value) => setSheetState(() => query = value.trim()),
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

  Future<void> _load() async {
    _loadToken?.cancel('Reload edit');
    final token = CancelToken();
    _loadToken = token;
    setState(() => _loading = true);

    try {
      final repo = _repoOrCreate();
      final deviceRes = await repo.getDeviceDetails(widget.deviceId, cancelToken: token);
      final typesRes = await repo.getDeviceTypes(cancelToken: token);
      final simsRes = await repo.getQuickSimCards(cancelToken: token);

      Map<String, dynamic> device = const <String, dynamic>{};
      List<DeviceTypeOption> types = const <DeviceTypeOption>[];
      List<SimOption> sims = const <SimOption>[];

      deviceRes.when(success: (d) => device = d, failure: (_) {});
      typesRes.when(success: (d) => types = d, failure: (_) {});
      simsRes.when(success: (d) => sims = d, failure: (_) {});

      final raw = widget.initialRaw ?? const <String, dynamic>{};
      final imei = (device['imei'] ?? raw['imei'] ?? '').toString().trim();
      final typeName = ((device['type'] is Map)
              ? (device['type']['name'] ?? '')
              : (device['deviceType'] is Map)
                  ? (device['deviceType']['name'] ?? '')
                  : (device['deviceTypeName'] ?? ''))
          .toString()
          .trim();
      String pickSimNumber(Map<String, dynamic> source) {
        final sim = source['sim'];
        if (sim is Map) {
          final nested = (sim['simNumber'] ?? sim['number'] ?? '').toString().trim();
          if (nested.isNotEmpty && nested.toLowerCase() != 'null') return nested;
        }
        final direct = (source['simNumber'] ?? source['simNo'] ?? '').toString().trim();
        if (direct.isNotEmpty && direct.toLowerCase() != 'null') return direct;
        return '';
      }

      final simNumberFromDevice = pickSimNumber(device);
      final simNumberFromList = pickSimNumber(raw);
      final simNumber = simNumberFromDevice.isNotEmpty
          ? simNumberFromDevice
          : simNumberFromList;
      final isActive = device['isActive'] == true ||
          device['active'] == true ||
          raw['isActive'] == true ||
          raw['active'] == true;

      if (!mounted) return;
      setState(() {
        _deviceTypes = types;
        _quickSims = sims;
        _imeiController.text = imei;
        final resolvedType = typeName.isNotEmpty
            ? typeName
            : (_deviceTypeLabels.isNotEmpty ? _deviceTypeLabels.first : null);
        final resolvedSim = simNumber.isNotEmpty ? simNumber : 'Unassigned';
        _selectedDeviceTypeLabel = resolvedType;
        _selectedSimLabel = resolvedSim;
        _currentSimText = simNumber.isNotEmpty ? simNumber : '—';
        _isActive = isActive;
        _selectedStatus = _normalizeStatus(device['status']);
        _initialImei = imei;
        _initialDeviceTypeLabel = resolvedType ?? '';
        _initialSimLabel = resolvedSim;
        _initialStatus = _normalizeStatus(device['status']);
        _initialIsActive = isActive;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack("Couldn't load device details.");
    }
  }

  Future<void> _save() async {
    if (_saving) return;
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

    final payload = <String, dynamic>{};

    if (imei != _initialImei) {
      payload['imei'] = imei;
    }

    if (typeLabel != _initialDeviceTypeLabel) {
      payload['deviceTypeId'] = int.tryParse(typeId) ?? typeId;
    }

    if (_selectedStatus != _initialStatus) {
      payload['status'] = _selectedStatus;
    }

    if (_isActive != _initialIsActive) {
      payload['isActive'] = _isActive;
    }

    if (simLabel != _initialSimLabel) {
      if (simId == _unassignedValue) {
        payload['simId'] = null;
      } else if (simId.isNotEmpty) {
        payload['simId'] = int.tryParse(simId) ?? simId;
      }
    }

    if (payload.isEmpty) {
      _snack('No changes to update.');
      return;
    }

    _saveToken?.cancel('Replace save');
    final token = CancelToken();
    _saveToken = token;

    setState(() => _saving = true);
    final res = await _repoOrCreate().updateDevice(
      widget.deviceId,
      payload,
      cancelToken: token,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    res.when(
      success: (_) {
        _snack('Device updated.');
        Navigator.pop(context, true);
      },
      failure: (e) {
        final message = e is ApiException && e.message.trim().isNotEmpty
            ? e.message
            : "Couldn't update device.";
        _snack(message);
      },
    );
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
    final horizontalPadding = AdaptiveUtils.isVerySmallScreen(screenWidth)
        ? 8.0
        : AdaptiveUtils.isSmallScreen(screenWidth)
            ? 10.0
            : 12.0;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F7),
      bottomNavigationBar: _loading
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
                          onPressed: _saving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: cs.onSurface.withOpacity(0.2)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.roboto(
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
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _saving ? 'Saving...' : 'Save',
                            style: GoogleFonts.roboto(
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
              _loading ? 84 : 24,
            ),
            child: _loading
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
                                  setState(() => _selectedDeviceTypeLabel = picked);
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
                                  setState(() => _selectedSimLabel = picked);
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
                                  setState(() => _selectedStatus = picked);
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
                                            style: GoogleFonts.roboto(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Enable or disable this device.',
                                            style: GoogleFonts.roboto(
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
                                      onChanged: (v) => setState(() => _isActive = v),
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
          style: GoogleFonts.roboto(
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
            style: GoogleFonts.roboto(
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
          style: GoogleFonts.roboto(
            fontSize: fs,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          validator: validator,
          style: GoogleFonts.roboto(
            fontSize: fs,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.roboto(
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
          style: GoogleFonts.roboto(
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
                    style: GoogleFonts.roboto(
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
