// components/vehicle/vehicle_config_tab.dart
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleConfigTab extends StatefulWidget {
  const VehicleConfigTab({super.key});

  @override
  State<VehicleConfigTab> createState() => _VehicleConfigTabState();
}

class _VehicleConfigTabState extends State<VehicleConfigTab> {
  final TextEditingController speedController = TextEditingController(text: "1.00");
  final TextEditingController distanceController = TextEditingController(text: "1.00");
  final TextEditingController odometerController = TextEditingController(text: "0");
  final TextEditingController engineHoursController = TextEditingController(text: "0");

  String ignitionSource = "Ignition Wire";

  void _increment(TextEditingController controller, [double step = 0.01]) {
    double value = double.tryParse(controller.text) ?? 0;
    value += step;
    controller.text = step < 1 ? value.toStringAsFixed(2) : value.toStringAsFixed(0);
    setState(() {});
  }

  void _decrement(TextEditingController controller, [double step = 0.01]) {
    double value = double.tryParse(controller.text) ?? 0;
    value -= step;
    if (value < 0) value = 0;
    controller.text = step < 1 ? value.toStringAsFixed(2) : value.toStringAsFixed(0);
    setState(() {});
  }

  Widget _numberField({
    required TextEditingController controller,
    required String unit,
    double step = 0.01,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double fs = AdaptiveUtils.getTitleFontSize(width);

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.inter(fontSize: fs, color: colorScheme.onSurface),
      decoration: InputDecoration(
        filled: true,
        fillColor: colorScheme.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(onTap: () => _increment(controller, step), child: Icon(Icons.arrow_drop_up, size: 18, color: colorScheme.onSurface)),
                InkWell(onTap: () => _decrement(controller, step), child: Icon(Icons.arrow_drop_down, size: 18, color: colorScheme.onSurface)),
              ],
            ),
            const SizedBox(width: 8),
            Text(unit, style: GoogleFonts.inter(fontSize: fs, fontWeight: FontWeight.bold, color: colorScheme.onSurface.withOpacity(0.87))),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _configBox({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required String unit,
    double step = 0.01,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double fs = AdaptiveUtils.getTitleFontSize(width);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: fs + 2, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.9))),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.inter(fontSize: fs - 2, color: colorScheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 14),
          _numberField(controller: controller, unit: unit, step: step),
        ],
      ),
    );
  }

  Widget _ignitionSourceBox() {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double fs = AdaptiveUtils.getTitleFontSize(width);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Ignition Source", style: GoogleFonts.inter(fontSize: fs + 2, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.9))),
          const SizedBox(height: 4),
          Text("Choose how engine ON/OFF is derived.", style: GoogleFonts.inter(fontSize: fs - 2, color: colorScheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  activeColor: colorScheme.primary,
                  title: Text("Ignition Wire", style: GoogleFonts.inter(fontSize: fs - 1, color: colorScheme.onSurface)),
                  value: "Ignition Wire",
                  groupValue: ignitionSource,
                  onChanged: (v) => v != null ? setState(() => ignitionSource = v) : null,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  activeColor: colorScheme.primary,
                  title: Text("Motion-Based", style: GoogleFonts.inter(fontSize: fs - 1, color: colorScheme.onSurface)),
                  value: "Motion-Based",
                  groupValue: ignitionSource,
                  onChanged: (v) => v != null ? setState(() => ignitionSource = v) : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double fs = AdaptiveUtils.getTitleFontSize(width);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP BUTTONS
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () => setState(() => ignitionSource = "Ignition Wire"),
                child: Text("Reset", style: GoogleFonts.inter(fontSize: fs - 2, color: colorScheme.onSurface)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                onPressed: () {},
                child: Text("Save", style: GoogleFonts.inter(fontSize: fs - 2, color: colorScheme.onPrimary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // TITLE
          Text("Vehicle Setting Configuration", style: GoogleFonts.inter(fontSize: fs + 1, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 24),

          // CONFIG BOXES
          _configBox(title: "Speed Multiplier (×)", subtitle: "Multiply raw speed by this factor (e.g., 0.95, 1.00, 1.05).", controller: speedController, unit: "×"),
          _configBox(title: "Distance Multiplier (×)", subtitle: "Multiply raw distance by this factor (e.g., 0.98, 1.00, 1.10).", controller: distanceController, unit: "×"),
          _configBox(title: "Set Odometer", subtitle: "Override odometer baseline (km).", controller: odometerController, unit: "km", step: 1),
          _configBox(title: "Set Engine Hours", subtitle: "Total engine runtime hours.", controller: engineHoursController, unit: "h", step: 1),
          _ignitionSourceBox(),
        ],
      ),
    );
  }
}