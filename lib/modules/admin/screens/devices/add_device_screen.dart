import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/device_type_option.dart';
import 'package:fleet_stack/core/models/sim_option.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_devices_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  // Endpoint truth table (FleetStack-API-Reference.md + Postman):
  // - GET /devicestypes
  // - GET /admin/simcards
  // - POST /admin/devices body: { imei, deviceTypeId, simId? }

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _imeiController = TextEditingController();

  String? _selectedDeviceTypeLabel;
  String? _selectedSimLabel;

  List<DeviceTypeOption> _deviceTypes = const <DeviceTypeOption>[];
  List<SimOption> _sims = const <SimOption>[];

  bool _loadingRefs = false;
  bool _submitting = false;
  bool _loadErrorShown = false;

  CancelToken? _loadToken;
  CancelToken? _submitToken;

  ApiClient? _apiClient;
  AdminDevicesRepository? _repo;

  AdminDevicesRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminDevicesRepository(api: _apiClient!);
    return _repo!;
  }

  @override
  void initState() {
    super.initState();
    _loadReferenceData();
  }

  @override
  void dispose() {
    _loadToken?.cancel('AddDeviceScreen disposed');
    _submitToken?.cancel('AddDeviceScreen disposed');
    _imeiController.dispose();
    super.dispose();
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  void _showLoadErrorOnce(String message) {
    if (_loadErrorShown || !mounted) return;
    _loadErrorShown = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadReferenceData() async {
    _loadToken?.cancel('Reload device references');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loadingRefs = true);

    try {
      final repo = _repoOrCreate();
      final typesRes = await repo.getDeviceTypes(cancelToken: token);
      final simsRes = await repo.getSims(cancelToken: token);
      if (!mounted) return;

      List<DeviceTypeOption> types = const <DeviceTypeOption>[];
      List<SimOption> sims = const <SimOption>[];
      Object? firstError;

      typesRes.when(
        success: (items) {
          types = items;
        },
        failure: (err) {
          firstError ??= err;
        },
      );

      simsRes.when(
        success: (items) {
          sims = items;
        },
        failure: (err) {
          firstError ??= err;
        },
      );

      if (!mounted) return;
      setState(() {
        _deviceTypes = types;
        _sims = sims;
        _loadingRefs = false;
        if (firstError == null) {
          _loadErrorShown = false;
        }
      });

      if (firstError != null) {
        if (_isCancelled(firstError!)) return;
        _showLoadErrorOnce("Couldn't load device references.");
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _deviceTypes = const <DeviceTypeOption>[];
        _sims = const <SimOption>[];
        _loadingRefs = false;
      });
      _showLoadErrorOnce("Couldn't load device references.");
    }
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
    final labels = _sims
        .map((e) => e.label.trim())
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

  String _simIdFromLabel(String label) {
    final match = _sims.where((e) => e.label.trim() == label).toList();
    if (match.isEmpty) return '';
    return match.first.id.trim();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    final imei = _imeiController.text.trim();
    final typeLabel = (_selectedDeviceTypeLabel ?? '').trim();

    if (typeLabel.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select device type.')));
      return;
    }

    final typeId = _deviceTypeIdFromLabel(typeLabel);
    if (typeId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected device type is invalid.')),
      );
      return;
    }

    final simLabel = (_selectedSimLabel ?? '').trim();
    final simId = simLabel.isEmpty ? '' : _simIdFromLabel(simLabel);

    _submitToken?.cancel('Replace add device request');
    final token = CancelToken();
    _submitToken = token;

    if (!mounted) return;
    setState(() => _submitting = true);

    try {
      final result = await _repoOrCreate().addDevice(
        imei: imei,
        deviceTypeId: typeId,
        simId: simId.isEmpty ? null : simId,
        cancelToken: token,
      );
      if (!mounted) return;

      result.when(
        success: (_) {
          if (!mounted) return;
          setState(() => _submitting = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Device added.')));
          Navigator.pop(context, true);
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _submitting = false);

          if (_isCancelled(err)) return;

          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to add device.'
              : "Couldn't add device.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't add device.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w);

    final deviceTypeLabels = _deviceTypeLabels;
    final simLabels = _simLabels;

    final selectedTypeStillExists =
        _selectedDeviceTypeLabel != null &&
        deviceTypeLabels.contains(_selectedDeviceTypeLabel);
    final selectedSimStillExists =
        _selectedSimLabel != null && simLabels.contains(_selectedSimLabel);

    if (!selectedTypeStillExists) {
      _selectedDeviceTypeLabel = null;
    }
    if (!selectedSimStillExists) {
      _selectedSimLabel = null;
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding * 1.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add New Device',
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _submitting
                        ? null
                        : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        StylishTextField(
                          label: 'IMEI',
                          hint: 'Enter IMEI number',
                          controller: _imeiController,
                          prefixIcon: Icons.device_hub_rounded,
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return 'Required';
                            return null;
                          },
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        if (_loadingRefs)
                          _dropdownShimmer(
                            label: 'Select device type',
                            width: w,
                          )
                        else
                          StylishDropdown(
                            label: 'Select device type',
                            hint: deviceTypeLabels.isEmpty
                                ? '—'
                                : 'Select device type',
                            value: _selectedDeviceTypeLabel,
                            items: deviceTypeLabels,
                            onChanged: deviceTypeLabels.isEmpty
                                ? null
                                : (v) => setState(
                                    () => _selectedDeviceTypeLabel = v,
                                  ),
                            width: w,
                          ),

                        const SizedBox(height: 16),

                        if (_loadingRefs)
                          _dropdownShimmer(
                            label: 'Select SIM (optional)',
                            width: w,
                          )
                        else
                          StylishDropdown(
                            label: 'Select SIM (optional)',
                            hint: simLabels.isEmpty ? '—' : 'Select SIM',
                            value: _selectedSimLabel,
                            items: simLabels,
                            onChanged: simLabels.isEmpty
                                ? null
                                : (v) => setState(() => _selectedSimLabel = v),
                            width: w,
                          ),

                        const SizedBox(height: 32),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _submitting
                                    ? null
                                    : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: cs.primary.withOpacity(0.2),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: (_submitting || _loadingRefs)
                                    ? null
                                    : _submit,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _submitting
                                    ? const SizedBox(
                                        height: 16,
                                        child: Center(
                                          child: AppShimmer(
                                            width: 88,
                                            height: 14,
                                            radius: 7,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'Add Device',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdownShimmer({required String label, required double width}) {
    final fs = AdaptiveUtils.getTitleFontSize(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: fs),
        ),
        const SizedBox(height: 8),
        const AppShimmer(width: double.infinity, height: 55, radius: 16),
      ],
    );
  }
}

class StylishTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final double width;

  const StylishTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.prefixIcon,
    this.validator,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fs = AdaptiveUtils.getTitleFontSize(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: fs),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 55,
          child: TextFormField(
            controller: controller,
            validator: validator,
            decoration: InputDecoration(
              fillColor: cs.surface,
              filled: true,
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                color: cs.onSurface.withOpacity(0.6),
                fontSize: fs,
              ),
              prefixIcon: Icon(prefixIcon, color: cs.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: cs.outline.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: cs.primary, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class StylishDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final double width;

  const StylishDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fs = AdaptiveUtils.getTitleFontSize(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: fs),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 55,
          child: DropdownButtonFormField<String>(
            iconEnabledColor: cs.primary,
            iconDisabledColor: cs.primary,
            focusColor: cs.surface,
            value: value,
            hint: Text(
              hint,
              style: GoogleFonts.inter(
                color: cs.onSurface.withOpacity(0.6),
                fontSize: fs,
              ),
            ),
            decoration: InputDecoration(
              fillColor: cs.surface,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: cs.outline.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: cs.primary, width: 2),
              ),
            ),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
