import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/common_repository.dart';
import 'package:fleet_stack/core/repositories/user_vehicles_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _imeiController = TextEditingController();
  final TextEditingController _vehicleNoController = TextEditingController();
  final TextEditingController _vinController = TextEditingController();

  String? selectedGMT;
  String? selectedVehicleType;

  List<ReferenceOption> _vehicleTypes = const <ReferenceOption>[];
  bool _loadingRefs = false;
  bool _saving = false;
  bool _loadErrorShown = false;

  ApiClient? _api;
  CommonRepository? _commonRepo;
  UserVehiclesRepository? _vehiclesRepo;
  CancelToken? _refsToken;
  CancelToken? _saveToken;

  final List<String> gmtOptions = [
    "GMT+05:30 (India)",
    "GMT+00:00 (UTC)",
    "GMT+01:00 (Europe)",
    "GMT-05:00 (EST)",
    "GMT-08:00 (PST)",
  ];

  @override
  void initState() {
    super.initState();
    _loadVehicleTypes();
  }

  @override
  void dispose() {
    _refsToken?.cancel('Add vehicle disposed');
    _saveToken?.cancel('Add vehicle disposed');
    _imeiController.dispose();
    _vehicleNoController.dispose();
    _vinController.dispose();
    super.dispose();
  }

  CommonRepository _commonOrCreate() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _commonRepo ??= CommonRepository(api: _api!);
    return _commonRepo!;
  }

  UserVehiclesRepository _vehiclesOrCreate() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _vehiclesRepo ??= UserVehiclesRepository(api: _api!);
    return _vehiclesRepo!;
  }

  Future<void> _loadVehicleTypes() async {
    _refsToken?.cancel('Reload vehicle types');
    final token = CancelToken();
    _refsToken = token;

    if (!mounted) return;
    setState(() => _loadingRefs = true);

    try {
      final res = await _commonOrCreate().getVehicleTypes(cancelToken: token);
      if (!mounted || token.isCancelled) return;

      res.when(
        success: (items) {
          setState(() {
            _vehicleTypes = items;
            _loadingRefs = false;
            _loadErrorShown = false;
          });
        },
        failure: (error) {
          setState(() => _loadingRefs = false);
          if (_loadErrorShown) return;
          _loadErrorShown = true;
          var msg = "Couldn't load vehicle types.";
          if (error is ApiException && error.message.trim().isNotEmpty) {
            msg = error.message;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRefs = false);
      if (_loadErrorShown) return;
      _loadErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load vehicle types.")),
      );
    }
  }

  String _gmtOffsetValue(String? label) {
    final raw = (label ?? '').trim();
    final match = RegExp(r'[+-]\d{2}:\d{2}').firstMatch(raw);
    if (match != null) return match.group(0)!;
    return raw;
  }

  String? get _selectedVehicleTypeId {
    final selected = selectedVehicleType;
    if (selected == null) return null;
    for (final item in _vehicleTypes) {
      if (item.label == selected) return item.value;
    }
    return null;
  }

  Future<void> _saveVehicle() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if (selectedGMT == null || selectedVehicleType == null) return;

    final typeId = _selectedVehicleTypeId;
    if (typeId == null || typeId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle type is required.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _saving = true);

    _saveToken?.cancel('Restart add vehicle');
    final token = CancelToken();
    _saveToken = token;

    final plateNumber = _vehicleNoController.text.trim();
    final payload = <String, dynamic>{
      // Postman-confirmed create keys for /user/vehicles:
      // name, vin, plateNumber, imei, simNumber, vehicleTypeId, gmtOffset
      // Current UI has no separate name/sim field, so name mirrors plateNumber
      // and simNumber is omitted until the UI exposes it.
      'name': plateNumber,
      'plateNumber': plateNumber,
      'imei': _imeiController.text.trim(),
      'vehicleTypeId': int.tryParse(typeId) ?? typeId,
      'gmtOffset': _gmtOffsetValue(selectedGMT),
      if (_vinController.text.trim().isNotEmpty)
        'vin': _vinController.text.trim(),
    };

    try {
      final res = await _vehiclesOrCreate().createVehicle(
        payload,
        cancelToken: token,
      );
      if (!mounted || token.isCancelled) return;

      res.when(
        success: (_) {
          Navigator.pop(context, true);
        },
        failure: (error) {
          if (!mounted) return;
          setState(() => _saving = false);
          var msg = "Couldn't add vehicle.";
          if (error is ApiException && error.message.trim().isNotEmpty) {
            msg = error.message;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't add vehicle.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding * 1.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── HEADER ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add Vehicle",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ─── FORM ───────────────────────────────
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        StylishTextField(
                          label: "IMEI",
                          hint: "Enter IMEI number",
                          controller: _imeiController,
                          prefixIcon: Icons.device_hub_rounded,
                          validator: (v) =>
                              v == null || v.isEmpty ? "Required" : null,
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        StylishTextField(
                          label: "Vehicle Number *",
                          hint: "Enter vehicle number",
                          controller: _vehicleNoController,
                          prefixIcon: Icons.directions_car,
                          validator: (v) =>
                              v == null || v.isEmpty ? "Required" : null,
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        StylishTextField(
                          label: "VIN Number (Optional)",
                          hint: "Enter VIN number",
                          controller: _vinController,
                          prefixIcon: Icons.confirmation_number,
                          validator: null, // Optional
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        StylishDropdown(
                          label: "Select GMT *",
                          hint: "Select GMT",
                          value: selectedGMT,
                          items: gmtOptions,
                          onChanged: (v) => setState(() => selectedGMT = v),
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        if (_loadingRefs)
                          const AppShimmer(
                            width: double.infinity,
                            height: 84,
                            radius: 16,
                          )
                        else
                          StylishDropdown(
                            label: "Vehicle Type *",
                            hint: "Select Vehicle Type",
                            value: selectedVehicleType,
                            items: _vehicleTypes
                                .map((item) => item.label)
                                .toList(),
                            onChanged: (v) =>
                                setState(() => selectedVehicleType = v),
                            width: w,
                          ),

                        const SizedBox(height: 32),

                        // ─── ACTION BUTTONS ─────────────────
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
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
                                  "Back",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saving ? null : _saveVehicle,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _saving
                                    ? const AppShimmer(
                                        width: 88,
                                        height: 16,
                                        radius: 8,
                                      )
                                    : Text(
                                        "Add Vehicle",
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
}

/// ───────────────────────────────────────────────
/// STYLISH TEXT FIELD (Reused from previous example)
/// ───────────────────────────────────────────────
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

/// ───────────────────────────────────────────────
/// STYLISH DROPDOWN (Reused from previous example)
/// ───────────────────────────────────────────────
class StylishDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
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
            initialValue: value,
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
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, style: GoogleFonts.inter(fontSize: fs)),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            validator: (v) => v == null ? "Required" : null,
          ),
        ),
      ],
    );
  }
}
