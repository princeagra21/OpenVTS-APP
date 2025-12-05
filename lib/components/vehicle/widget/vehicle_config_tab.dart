import 'package:flutter/material.dart';
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

  void increment(TextEditingController controller, [double step = 0.01]) {
    double value = double.tryParse(controller.text) ?? 0;
    value += step;
    controller.text = step < 1 ? value.toStringAsFixed(2) : value.toStringAsFixed(0);
    setState(() {});
  }

  void decrement(TextEditingController controller, [double step = 0.01]) {
    double value = double.tryParse(controller.text) ?? 0;
    value -= step;
    if (value < 0) value = 0;
    controller.text = step < 1 ? value.toStringAsFixed(2) : value.toStringAsFixed(0);
    setState(() {});
  }

  Widget numberField({
    required TextEditingController controller,
    required String unit,
    double step = 0.01,
  }) {
    return SizedBox(
      width: double.infinity,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        maxLength: 10,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.black),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.black),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.black),
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                        onTap: () => increment(controller, step),
                        child: const Icon(Icons.arrow_drop_up, size: 18, color: Colors.black)),
                    InkWell(
                        onTap: () => decrement(controller, step),
                        child: const Icon(Icons.arrow_drop_down, size: 18, color: Colors.black)),
                  ],
                ),
                const SizedBox(width: 6),
                Text(unit,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87))
              ],
            ),
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 50, minHeight: 30),
        ),
      ),
    );
  }

  Widget configBox({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required String unit,
    double step = 0.01,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 16),
          numberField(controller: controller, unit: unit, step: step),
        ],
      ),
    );
  }

  Widget ignitionSourceBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Ignition Source", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text("Choose how engine ON/OFF is derived.", style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: RadioListTile<String>(
                  activeColor: Colors.black,
                  title:  Text("Ignition Wire", style: GoogleFonts.inter(fontSize: 12, color: Colors.black),),
                  value: "Ignition Wire",
                  groupValue: ignitionSource,
                  onChanged: (value) {
                    setState(() {
                      ignitionSource = value!;
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  activeColor: Colors.black,
                  title:  Text("Motion-Based", style:  GoogleFonts.inter(fontSize: 12, color: Colors.black),),
                  value: "Motion-Based",
                  groupValue: ignitionSource,
                  onChanged: (value) {
                    setState(() {
                      ignitionSource = value!;
                    });
                  },
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Vehicle Setting Configuration",
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black.withOpacity(0.7))),
          const SizedBox(height: 16),

          configBox(
            title: "Speed Multiplier (×)",
            subtitle: "Multiply raw speed by this factor (e.g., 0.95, 1.00, 1.05).",
            controller: speedController,
            unit: "×",
            step: 0.01,
          ),

          configBox(
            title: "Distance Multiplier (×)",
            subtitle: "Multiply raw distance by this factor (e.g., 0.98, 1.00, 1.10).",
            controller: distanceController,
            unit: "×",
            step: 0.01,
          ),

          configBox(
            title: "Set Odometer",
            subtitle: "Override odometer baseline (km).",
            controller: odometerController,
            unit: "km",
            step: 1,
          ),

          configBox(
            title: "Set Engine Hours",
            subtitle: "Total engine runtime hours.",
            controller: engineHoursController,
            unit: "h",
            step: 1,
          ),

          ignitionSourceBox(),

          const SizedBox(height: 16),

          // Save and Reset buttons outside ignition box, aligned to bottom-right
          Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(Colors.black),
      ),
      onPressed: () {
        // Save logic here
      },
      child: const Text(
        "Save",
        style: TextStyle(color: Colors.white),
      ),
    ),
    const SizedBox(width: 12),
    OutlinedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(Colors.transparent),
        side: MaterialStateProperty.all<BorderSide>(
          BorderSide(color: Colors.black.withOpacity(0.5)),
        ),
      ),
      onPressed: () {
        setState(() {
          ignitionSource = "Ignition Wire";
        });
      },
      child: const Text("Reset", style: TextStyle(color: Colors.black),),
    ),
  ],
)

        ],
      ),
    );
  }
}
