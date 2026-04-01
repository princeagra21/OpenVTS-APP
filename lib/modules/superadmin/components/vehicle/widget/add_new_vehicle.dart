// screens/vehicle/add_vehicle_screen.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _userController = TextEditingController();
  final _vehicleNoController = TextEditingController();
  final _imeiController = TextEditingController();
  final _simController = TextEditingController();

  String? _selectedPricingPlan;
  String? _selectedDeviceType;
  String? _selectedVehicleType;

  final List<String> _fallbackPricingPlans = ["Basic", "Standard", "Premium"];
  late List<String> _pricingPlanNames;
  bool _loadingPricingPlans = false;
  bool _pricingPlansErrorShown = false;
  CancelToken? _pricingPlansCancelToken;
  CancelToken? _pricingPlansCapabilityCancelToken;

  ApiClient? _api;
  SuperadminRepository? _repo;

  final List<String> deviceTypes = ["FBM920", "GT06", "FM1200", "GV500"];
  final List<String> vehicleTypes = [
    "Car",
    "Truck",
    "SUV",
    "Bus",
    "Van",
    "Bike",
  ];

  @override
  void initState() {
    super.initState();
    _pricingPlanNames = List<String>.from(_fallbackPricingPlans);
    _initPricingPlans();
  }

  @override
  void dispose() {
    _pricingPlansCancelToken?.cancel('AddVehicleScreen disposed');
    _pricingPlansCapabilityCancelToken?.cancel('AddVehicleScreen disposed');
    _userController.dispose();
    _vehicleNoController.dispose();
    _imeiController.dispose();
    _simController.dispose();
    super.dispose();
  }

  Future<void> _initPricingPlans() async {
    _pricingPlansCapabilityCancelToken?.cancel(
      'Reload pricing plan capability',
    );
    final token = CancelToken();
    _pricingPlansCapabilityCancelToken = token;

    if (!mounted) return;
    setState(() => _loadingPricingPlans = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final capRes = await _repo!.canAccessAdminPricingPlans(
        cancelToken: token,
      );
      if (!mounted) return;

      capRes.when(
        success: (canAccess) {
          if (!mounted) return;
          if (!canAccess) {
            setState(() => _loadingPricingPlans = false);
            if (_pricingPlansErrorShown) return;
            _pricingPlansErrorShown = true;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Not authorized to view plans.')),
            );
            return;
          }

          // Authorized: load the full list (keeps fallback-first behavior).
          _loadPricingPlans(startLoading: false);
        },
        failure: (_) {
          if (!mounted) return;
          setState(() => _loadingPricingPlans = false);
          if (_pricingPlansErrorShown) return;
          _pricingPlansErrorShown = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Couldn't load plans. Showing fallback list."),
            ),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPricingPlans = false);
      if (_pricingPlansErrorShown) return;
      _pricingPlansErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't load plans. Showing fallback list."),
        ),
      );
    }
  }

  Future<void> _loadPricingPlans({bool startLoading = true}) async {
    _pricingPlansCancelToken?.cancel('Reload pricing plans');
    final token = CancelToken();
    _pricingPlansCancelToken = token;

    if (!mounted) return;
    if (startLoading) {
      setState(() => _loadingPricingPlans = true);
    }

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final res = await _repo!.getPricingPlans(cancelToken: token);
      if (!mounted) return;

      res.when(
        success: (plans) {
          if (!mounted) return;
          final names = plans
              .map((p) => p.name.trim())
              .where((s) => s.isNotEmpty)
              .toList();

          setState(() {
            _loadingPricingPlans = false;
            _pricingPlansErrorShown = false;
            _pricingPlanNames = names.isNotEmpty ? names : const ["No data"];
            if (_pricingPlanNames.length == 1 &&
                _pricingPlanNames.first == "No data") {
              _selectedPricingPlan = null;
            }
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _loadingPricingPlans = false);
          if (_pricingPlansErrorShown) return;
          _pricingPlansErrorShown = true;

          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to view plans.'
              : "Couldn't load plans. Showing fallback list.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPricingPlans = false);
      if (_pricingPlansErrorShown) return;
      _pricingPlansErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't load plans. Showing fallback list."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(w);
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(w); // ~18–22
    final double labelSize = AdaptiveUtils.getTitleFontSize(w); // ~14–16

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(hp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add New Vehicle",
                    style: GoogleFonts.roboto(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close_rounded,
                      size: 28,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  "Register a new vehicle",
                  style: GoogleFonts.roboto(
                    fontSize: labelSize + 2,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // ── Fields ─────────────────────────────────────
                      StylishTextField(
                        controller: _userController,
                        label: "User",
                        hint: "Select or add new user",
                        prefixIcon: Icons.person_rounded,
                      ),
                      const SizedBox(height: 16),

                      StylishTextField(
                        controller: _vehicleNoController,
                        label: "Vehicle Number",
                        hint: "e.g. KA-01-HH-1234",
                        prefixIcon: Icons.directions_car_rounded,
                      ),
                      const SizedBox(height: 16),

                      StylishTextField(
                        controller: _imeiController,
                        label: "IMEI",
                        hint: "Search IMEI or add new",
                        prefixIcon: Icons.search_rounded,
                      ),
                      const SizedBox(height: 16),

                      StylishTextField(
                        controller: _simController,
                        label: "SIM Number",
                        hint: "Search SIM or add new",
                        prefixIcon: Icons.sim_card_rounded,
                      ),
                      const SizedBox(height: 24),

                      // ── Dropdowns ─────────────────────────────────────
                      StylishDropdown(
                        label: "Select Plan",
                        hint: "Choose subscription plan",
                        value: _selectedPricingPlan,
                        items: _pricingPlanNames,
                        loading: _loadingPricingPlans,
                        onChanged:
                            (_pricingPlanNames.length == 1 &&
                                _pricingPlanNames.first == "No data")
                            ? null
                            : (v) => setState(() => _selectedPricingPlan = v),
                      ),
                      const SizedBox(height: 16),

                      StylishDropdown(
                        label: "Device Type",
                        hint: "Select tracker model",
                        value: _selectedDeviceType,
                        items: deviceTypes,
                        onChanged: (v) =>
                            setState(() => _selectedDeviceType = v),
                      ),
                      const SizedBox(height: 16),

                      StylishDropdown(
                        label: "Vehicle Type",
                        hint: "Select vehicle category",
                        value: _selectedVehicleType,
                        items: vehicleTypes,
                        onChanged: (v) =>
                            setState(() => _selectedVehicleType = v),
                      ),
                      const SizedBox(height: 32),

                      // ── Save Button ─────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Add vehicle logic
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: Text(
                            "Add Vehicle",
                            style: GoogleFonts.roboto(
                              fontSize: labelSize + 2,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
// REUSABLE STYLISH TEXTFIELD (exactly like SMTP screen)
// ───────────────────────────────────────────────────────────────
class StylishTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;

  const StylishTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double fs = AdaptiveUtils.getTitleFontSize(w);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: fs,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.87),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: GoogleFonts.roboto(fontSize: fs, color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.roboto(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontSize: fs,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: colorScheme.primary,
              size: fs + 6,
            ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────────
// REUSABLE STYLISH DROPDOWN (same as the one I gave you earlier)
// ───────────────────────────────────────────────────────────────
class StylishDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<String> items;
  final bool loading;
  final ValueChanged<String?>? onChanged;

  const StylishDropdown({
    super.key,
    required this.label,
    required this.hint,
    this.value,
    required this.items,
    this.loading = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double fs = AdaptiveUtils.getTitleFontSize(w);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: label,
                style: GoogleFonts.roboto(
                  fontSize: fs,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
              if (loading)
                const WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: AppShimmer(width: 14, height: 14, radius: 7),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: DropdownButton<String>(
            value: value,
            hint: Text(
              hint,
              style: GoogleFonts.roboto(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: fs,
              ),
            ),
            isExpanded: true,
            underline: const SizedBox.shrink(),
            icon: Icon(
              Icons.arrow_drop_down_rounded,
              color: colorScheme.onSurface.withOpacity(0.6),
              size: fs + 10,
            ),
            dropdownColor: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            style: GoogleFonts.roboto(
              fontSize: fs,
              color: colorScheme.onSurface,
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
