import 'package:open_vts/features/user/domain/entities/create_user_vehicle_input.dart';
import 'package:open_vts/features/user/presentation/controllers/add_vehicle_controller.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_feedback.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _imeiController = TextEditingController();
  final TextEditingController _vehicleNoController = TextEditingController();
  final TextEditingController _vinController = TextEditingController();

  String? selectedGMT;
  String? selectedVehicleType;


  final List<String> gmtOptions = [
    'GMT+05:30 (India)',
    'GMT+00:00 (UTC)',
    'GMT+01:00 (Europe)',
    'GMT-05:00 (EST)',
    'GMT-08:00 (PST)',
  ];

  @override
  void dispose() {
    _imeiController.dispose();
    _vehicleNoController.dispose();
    _vinController.dispose();
    super.dispose();
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
    for (final item in ref.read(userAddVehicleControllerProvider).vehicleTypes) {
      if (item.label == selected) return item.value;
    }
    return null;
  }

  Future<void> _saveVehicle() async {
    final formState = ref.read(userAddVehicleControllerProvider);
    if (formState.isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (selectedGMT == null || selectedVehicleType == null) return;

    final typeId = _selectedVehicleTypeId;
    if (typeId == null || typeId.trim().isEmpty) {
      OpenVtsFeedback.warning(context, 'Vehicle type is required.');
      return;
    }

    final ok = await ref.read(userAddVehicleControllerProvider.notifier).submit(
          CreateUserVehicleInput(
            imei: _imeiController.text.trim(),
            plateNumber: _vehicleNoController.text.trim(),
            vehicleTypeId: typeId,
            gmtOffset: _gmtOffsetValue(selectedGMT),
            vin: _vinController.text.trim().isEmpty ? null : _vinController.text.trim(),
          ),
        );

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      return;
    }

    OpenVtsFeedback.error(
      context,
      ref.read(userAddVehicleControllerProvider).errorMessage ?? 'Couldn\'t add vehicle.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final formState = ref.watch(userAddVehicleControllerProvider);
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
                    'Add Vehicle',
                    style: AppFonts.inter(
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
                          label: 'IMEI',
                          hint: 'Enter IMEI number',
                          controller: _imeiController,
                          prefixIcon: Icons.device_hub_rounded,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        StylishTextField(
                          label: 'Vehicle Number *',
                          hint: 'Enter vehicle number',
                          controller: _vehicleNoController,
                          prefixIcon: Icons.directions_car,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        StylishTextField(
                          label: 'VIN Number (Optional)',
                          hint: 'Enter VIN number',
                          controller: _vinController,
                          prefixIcon: Icons.confirmation_number,
                          validator: null, // Optional
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        StylishDropdown(
                          label: 'Select GMT *',
                          hint: 'Select GMT',
                          value: selectedGMT,
                          items: gmtOptions,
                          onChanged: (v) => updateLocalUiState(this, () => selectedGMT = v),
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        if (formState.isLoading)
                          const AppShimmer(
                            width: double.infinity,
                            height: 84,
                            radius: 16,
                          )
                        else
                          StylishDropdown(
                            label: 'Vehicle Type *',
                            hint: 'Select Vehicle Type',
                            value: selectedVehicleType,
                            items: formState.vehicleTypes
                                .map((item) => item.label)
                                .toList(),
                            onChanged: (v) =>
                                updateLocalUiState(this, () => selectedVehicleType = v),
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
                                  'Back',
                                  style: AppFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: formState.isSubmitting ? null : _saveVehicle,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: formState.isSubmitting
                                    ? const AppShimmer(
                                        width: 88,
                                        height: 16,
                                        radius: 8,
                                      )
                                    : Text(
                                        'Add Vehicle',
                                        style: AppFonts.inter(
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
          style: AppFonts.inter(fontWeight: FontWeight.w600, fontSize: fs),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 55,
          child: OpenVtsTextField(
            controller: controller,
            validator: validator,
            hintText: hint,
            prefixIcon: Icon(prefixIcon, color: cs.primary),
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
          style: AppFonts.inter(fontWeight: FontWeight.w600, fontSize: fs),
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
              style: AppFonts.inter(
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
                    child: Text(e, style: AppFonts.inter(fontSize: fs)),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            validator: (v) => v == null ? 'Required' : null,
          ),
        ),
      ],
    );
  }
}
