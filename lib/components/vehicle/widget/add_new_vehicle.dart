// screens/vehicle/add_vehicle_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';

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

  String? _selectedPlan;
  String? _selectedDeviceType;
  String? _selectedVehicleType;

  final List<String> plans = ["Basic", "Standard", "Premium"];
  final List<String> deviceTypes = ["FBM920", "GT06", "FM1200", "GV500"];
  final List<String> vehicleTypes = ["Car", "Truck", "SUV", "Bus", "Van", "Bike"];

  @override
  void dispose() {
    _userController.dispose();
    _vehicleNoController.dispose();
    _imeiController.dispose();
    _simController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(w);
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(w);     // ~18–22
    final double labelSize = AdaptiveUtils.getTitleFontSize(w);        // ~14–16

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
                    style: GoogleFonts.inter(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close_rounded, size: 28, color: colorScheme.onSurface.withOpacity(0.7)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  "Register a new vehicle",
                  style: GoogleFonts.inter(
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
                        value: _selectedPlan,
                        items: plans,
                        onChanged: (v) => setState(() => _selectedPlan = v),
                      ),
                      const SizedBox(height: 16),

                      StylishDropdown(
                        label: "Device Type",
                        hint: "Select tracker model",
                        value: _selectedDeviceType,
                        items: deviceTypes,
                        onChanged: (v) => setState(() => _selectedDeviceType = v),
                      ),
                      const SizedBox(height: 16),

                      StylishDropdown(
                        label: "Vehicle Type",
                        hint: "Select vehicle category",
                        value: _selectedVehicleType,
                        items: vehicleTypes,
                        onChanged: (v) => setState(() => _selectedVehicleType = v),
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
                            style: GoogleFonts.inter(
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
          style: GoogleFonts.inter(
            fontSize: fs,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.87),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: GoogleFonts.inter(fontSize: fs, color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: colorScheme.onSurface.withOpacity(0.6), fontSize: fs),
            prefixIcon: Icon(prefixIcon, color: colorScheme.primary, size: fs + 6),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
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
  final ValueChanged<String?>? onChanged;

  const StylishDropdown({
    super.key,
    required this.label,
    required this.hint,
    this.value,
    required this.items,
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
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: fs,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.87),
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
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 3)),
            ],
          ),
          child: DropdownButton<String>(
            value: value,
            hint: Text(hint, style: GoogleFonts.inter(color: colorScheme.onSurface.withOpacity(0.6), fontSize: fs)),
            isExpanded: true,
            underline: const SizedBox.shrink(),
            icon: Icon(Icons.arrow_drop_down_rounded, color: colorScheme.onSurface.withOpacity(0.6), size: fs + 10),
            dropdownColor: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            style: GoogleFonts.inter(fontSize: fs, color: colorScheme.onSurface),
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