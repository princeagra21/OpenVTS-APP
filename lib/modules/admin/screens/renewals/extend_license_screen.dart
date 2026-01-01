// screens/renewals/extend_license_screen.dart
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ExtendLicenseScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedDevices;

  const ExtendLicenseScreen({super.key, required this.selectedDevices});

  @override
  State<ExtendLicenseScreen> createState() => _ExtendLicenseScreenState();
}

class _ExtendLicenseScreenState extends State<ExtendLicenseScreen> {
  // Logic State
  String? selectedExtension = "Quarterly";
  final List<String> extensions = ["Quarterly", "Half-Year", "Annual", "Custom Months"];
  int customMonths = 3;
  
  late TextEditingController _monthsController;
  final DateFormat dateFormat = DateFormat('d MMM yyyy');
  final DateTime currentDate = DateTime.now();
  List<DateTime> newExpiries = [];

  @override
  void initState() {
    super.initState();
    _monthsController = TextEditingController(text: customMonths.toString());
    _calculateNewExpiries();
  }

  @override
  void dispose() {
    _monthsController.dispose();
    super.dispose();
  }

  /// Calculates new expiry dates based on current selection
  void _calculateNewExpiries() {
    newExpiries = widget.selectedDevices.map((device) {
      final currentExpiryStr = device['expiry'] as String;
      DateTime baseDate;
      try {
        baseDate = DateFormat('d MMM yyyy').parse(currentExpiryStr);
      } catch (e) {
        baseDate = currentDate;
      }

      // We use customMonths variable which is kept in sync with dropdown/textfield
      return baseDate.add(Duration(days: customMonths * 30));
    }).toList();
  }

  void _updateUI() {
    setState(() {
      _calculateNewExpiries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w);
    final double fs = AdaptiveUtils.getTitleFontSize(w);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(padding * 1.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── HEADER ─────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Extend License",
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
                    const SizedBox(height: 32),

                    // ─── EXTENSION PERIOD (DROPDOWN) ────────
                    StylishDropdown(
                      label: "Extension Period",
                      hint: "Select period",
                      value: selectedExtension,
                      items: extensions,
                      width: w,
                      onChanged: (v) {
                        setState(() {
                          selectedExtension = v;
                          if (v == "Quarterly") customMonths = 3;
                          else if (v == "Half-Year") customMonths = 6;
                          else if (v == "Annual") customMonths = 12;
                          
                          _monthsController.text = customMonths.toString();
                          _calculateNewExpiries();
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // ─── MONTHS TO ADD (TEXTFIELD) ──────────
                    StylishTextField(
                      label: "Months to add",
                      hint: "Enter number of months",
                      controller: _monthsController,
                      prefixIcon: Icons.calendar_month_rounded,
                      width: w,
                      onChanged: (v) {
                        final parsed = int.tryParse(v) ?? 0;
                        setState(() {
                          customMonths = parsed;
                          // If user types manually, set dropdown to Custom
                          if (selectedExtension != "Custom Months") {
                            selectedExtension = "Custom Months";
                          }
                          _calculateNewExpiries();
                        });
                      },
                    ),

                    const SizedBox(height: 32),

                    // ─── PREVIEW SECTION ────────────────────
                    Text(
                      "New Expiry Dates",
                      style: GoogleFonts.inter(
                        fontSize: fs,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: widget.selectedDevices.asMap().entries.map((entry) {
                            final index = entry.key;
                            final device = entry.value;
                            final newDate = newExpiries.length > index ? newExpiries[index] : currentDate;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      "${device['vehicle']} (${device['imei']})",
                                      style: GoogleFonts.inter(fontSize: fs - 2),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    dateFormat.format(newDate),
                                    style: GoogleFonts.inter(
                                      fontSize: fs - 2,
                                      fontWeight: FontWeight.bold,
                                      color: cs.primary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ─── ACTION BUTTONS ─────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(padding * 1.3, 0, padding * 1.3, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: cs.primary.withOpacity(0.3)),
                        foregroundColor: cs.primary,
                      ),
                      child: Text("Cancel", style: GoogleFonts.inter(fontSize: fs, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: customMonths > 0 ? () {
                        // Action: Apply extension
                        Navigator.pop(context);
                      } : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: Text("Extend", style: GoogleFonts.inter(fontSize: fs, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ───────────────────────────────────────────────
/// STYLISH DROPDOWN WIDGET
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
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3)),
            ],
          ),
          child: DropdownButtonFormField<String>(
            iconEnabledColor: cs.primary,
            iconDisabledColor: cs.primary,
            value: value,
            hint: Text(hint, style: GoogleFonts.inter(color: cs.onSurface.withOpacity(0.6), fontSize: fs)),
            decoration: InputDecoration(
              fillColor: cs.surface,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// ───────────────────────────────────────────────
/// STYLISH TEXT FIELD WIDGET
/// ───────────────────────────────────────────────
class StylishTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final IconData prefixIcon;
  final double width;
  final ValueChanged<String>? onChanged;

  const StylishTextField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    required this.prefixIcon,
    required this.width,
    this.onChanged,
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
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3)),
            ],
          ),
          child: TextFormField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              fillColor: cs.surface,
              filled: true,
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: cs.onSurface.withOpacity(0.6), fontSize: fs),
              prefixIcon: Icon(prefixIcon, color: cs.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
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