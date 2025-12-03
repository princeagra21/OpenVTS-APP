import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _vehicleNoController = TextEditingController();
  final TextEditingController _imeiController = TextEditingController();
  final TextEditingController _simController = TextEditingController();

  String? _selectedPlan;
  String? _selectedDeviceType;
  String? _selectedVehicleType;

  final List<String> plans = ["Basic", "Standard", "Premium"];
  final List<String> deviceTypes = ["FBM920", "GT06", "FM1200", "GV500"];
  final List<String> vehicleTypes = ["Car", "Truck", "SUV", "Bus", "Van", "Bike"];

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w) + 6;
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(w);
    final double labelSize = AdaptiveUtils.getTitleFontSize(w);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- Top Header ----------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add New Vehicle",
                    style: GoogleFonts.inter(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 26),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Center(
                child: Text(
                  "Register a new vehicle",
                  style: GoogleFonts.inter(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ---------- Select or Add User ----------
              _buildTextField(
                controller: _userController,
                hint: "Select User or Add New User",
                prefixIcon: const Icon(Icons.person, color: Colors.black),
              ),

              const SizedBox(height: 12),

              // ---------- Vehicle Number ----------
              _buildTextField(
                controller: _vehicleNoController,
                hint: "Vehicle Number",
                prefixIcon: const Icon(Icons.confirmation_number, color: Colors.black),
              ),

              const SizedBox(height: 12),

              // ---------- IMEI ----------
              _buildTextField(
                controller: _imeiController,
                hint: "Search IMEI or Add New",
                prefixIcon: const Icon(Icons.search, color: Colors.black),
              ),

              const SizedBox(height: 12),

              // ---------- SIM Number ----------
              _buildTextField(
                controller: _simController,
                hint: "Search SIM or Add New",
                prefixIcon: const Icon(Icons.sim_card, color: Colors.black),
              ),

              const SizedBox(height: 12),

              // ---------- Select Plan ----------
              _buildDropdown(
                title: "Select Plan",
                items: plans,
                value: _selectedPlan,
                onChanged: (v) => setState(() => _selectedPlan = v),
              ),

              const SizedBox(height: 12),

              // ---------- Select Device Type ----------
              _buildDropdown(
                title: "Select Device Type",
                items: deviceTypes,
                value: _selectedDeviceType,
                onChanged: (v) => setState(() => _selectedDeviceType = v),
              ),

              const SizedBox(height: 12),

              // ---------- Select Vehicle Type ----------
              _buildDropdown(
                title: "Select Vehicle Type",
                items: vehicleTypes,
                value: _selectedVehicleType,
                onChanged: (v) => setState(() => _selectedVehicleType = v),
              ),

              const SizedBox(height: 20),

              // ---------- SAVE BUTTON ----------
              _infinityButton(
                text: "Add Vehicle",
                fontSize: labelSize,
                onTap: () {
                  // TODO: save logic
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // REUSABLE TEXTFIELD
  // ---------------------------------------------------------
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    Widget? prefixIcon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        prefixIcon: prefixIcon != null
            ? Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: prefixIcon)
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // REUSABLE DROPDOWN (MATCHES YOUR UI)
  // ---------------------------------------------------------
  Widget _buildDropdown({
    required String title,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(title, style: GoogleFonts.inter()),
        isExpanded: true,
        underline: const SizedBox(),
        style: GoogleFonts.inter(color: Colors.black, fontSize: 16),
        items: items.map((v) {
          return DropdownMenuItem(
            value: v,
            child: Text(v, style: GoogleFonts.inter(fontSize: 16)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  // ---------------------------------------------------------
  // FULL WIDTH BLACK BUTTON
  // ---------------------------------------------------------
  Widget _infinityButton({
    required String text,
    required double fontSize,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
