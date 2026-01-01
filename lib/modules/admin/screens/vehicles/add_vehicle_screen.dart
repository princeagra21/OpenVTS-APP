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

  final TextEditingController _vehicleNoController =
      TextEditingController();

  String? selectedUser;
  String? selectedImei;
  String? selectedSim;
  String? selectedVehicleType;
  String? selectedDeviceType;
  String? selectedPlan;

  final users = ["John Doe", "Fleet Admin", "New User"];
  final imeis = ["123456789012345", "987654321098765"];
  final sims = ["08012345678", "09087654321"];
  final vehicleTypes = ["Car", "Truck", "Bus", "Bike"];
  final deviceTypes = ["GT06", "FM1200", "GV500"];
  final plans = ["Basic", "Standard", "Premium"];

  @override
  void dispose() {
    _vehicleNoController.dispose();
    super.dispose();
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
                  )
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
                        StylishSelectWithAdd(
                          label: "Select User",
                          hint: "Select user",
                          value: selectedUser,
                          items: users,
                          onChanged: (v) =>
                              setState(() => selectedUser = v),
                          onAdd: () {},
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        StylishTextField(
                          label: "Vehicle No.",
                          hint: "Enter vehicle number",
                          controller: _vehicleNoController,
                          prefixIcon: Icons.directions_car_rounded,
                          validator: (v) =>
                              v == null || v.isEmpty ? "Required" : null,
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        StylishSelectWithAdd(
                          label: "Select IMEI",
                          hint: "Search IMEI",
                          value: selectedImei,
                          items: imeis,
                          onChanged: (v) =>
                              setState(() => selectedImei = v),
                          onAdd: () {},
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        StylishSelectWithAdd(
                          label: "Select SIM",
                          hint: "Search SIM",
                          value: selectedSim,
                          items: sims,
                          onChanged: (v) =>
                              setState(() => selectedSim = v),
                          onAdd: () {},
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        StylishDropdown(
                          label: "Vehicle Type",
                          hint: "Select Vehicle Type",
                          value: selectedVehicleType,
                          items: vehicleTypes,
                          onChanged: (v) =>
                              setState(() => selectedVehicleType = v),
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        StylishDropdown(
                          label: "Device Type",
                          hint: "Select Device Type",
                          value: selectedDeviceType,
                          items: deviceTypes,
                          onChanged: (v) =>
                              setState(() => selectedDeviceType = v),
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        StylishDropdown(
                          label: "Plan",
                          hint: "Select Plan",
                          value: selectedPlan,
                          items: plans,
                          onChanged: (v) => setState(() => selectedPlan = v),
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
          minimumSize: const Size.fromHeight(36), // reduced by 30%
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: cs.primary.withOpacity(0.2)),
          ),
        ),
        child: Text(
          "Cancel",
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // SUBMIT LOGIC
          }
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(36), // reduced by 30%
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          "Add Vehicle",
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
              SizedBox(height: 20,)
            ],
          ),
        ),
      ),
    );
  }
}

/// ───────────────────────────────────────────────
/// STYLISH TEXT FIELD
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
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, fontSize: fs),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 55,
          child: TextFormField(
            controller: controller,
            validator: validator,
            decoration: InputDecoration(
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
                borderSide:
                    BorderSide(color: cs.outline.withOpacity(0.3)),
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
/// STYLISH DROPDOWN
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
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, fontSize: fs),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 55,
          child: DropdownButtonFormField<String>(
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            items: items
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// ───────────────────────────────────────────────
/// SELECT WITH ADD BUTTON (USER / IMEI / SIM)
/// ───────────────────────────────────────────────
class StylishSelectWithAdd extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final VoidCallback onAdd;
  final double width;

  const StylishSelectWithAdd({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.onAdd,
    required this.width,

  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;    
    final fs = AdaptiveUtils.getTitleFontSize(width);


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
           style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, fontSize: fs),),
        const SizedBox(height: 8),
        Container(
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outline.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: value,
                    hint: Text(hint),
                    items: items
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: cs.primary),
                onPressed: onAdd,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
