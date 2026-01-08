// screens/map/add_landmark_screen.dart
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/shared/components/custom_dropdown_field.dart';
import 'package:fleet_stack/shared/components/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

class LandmarkOption {
  final String label;
  final double lat;
  final double lng;
  const LandmarkOption(this.label, this.lat, this.lng);

  @override
  String toString() => '$label\n$lat, $lng';
}

class AddLandmarkScreen extends StatefulWidget {
  final LatLng? initialPoint; // optional prefill (not used for dropdown selection)

  const AddLandmarkScreen({super.key, this.initialPoint});

  @override
  State<AddLandmarkScreen> createState() => _AddLandmarkScreenState();
}

class _AddLandmarkScreenState extends State<AddLandmarkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  IconData selectedIcon = Icons.location_on;

  // Dropdown value
  LandmarkOption? selectedOption;

  // Predefined list (use exact values you gave)
  static const List<LandmarkOption> presetLocations = [
    LandmarkOption('HQ Warehouse', 28.613900, 77.209000),
    LandmarkOption('Mumbai Port', 18.941000, 72.835000),
    LandmarkOption('Chennai Hub', 13.082700, 80.270700),
    LandmarkOption('Jaipur Yard', 26.912400, 75.787300),
    LandmarkOption('Kolkata Depot', 22.572600, 88.363900),
  ];

  final List<IconData> iconOptions = [
    Icons.location_on,
    Icons.place,
    Icons.flag,
    Icons.home,
    Icons.store,
    Icons.star,
  ];

  @override
  void initState() {
    super.initState();
    // Optionally preselect a location if initialPoint is close to one of the presets
    if (widget.initialPoint != null) {
      for (final opt in presetLocations) {
        if ((opt.lat - widget.initialPoint!.latitude).abs() < 0.001 &&
            (opt.lng - widget.initialPoint!.longitude).abs() < 0.001) {
          selectedOption = opt;
          _nameController.text = opt.label;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _labelForOption(LandmarkOption opt) =>
      '${opt.label} — ${opt.lat.toStringAsFixed(6)}, ${opt.lng.toStringAsFixed(6)}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(w);
    final fontSize = AdaptiveUtils.getTitleFontSize(w);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding * 1.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add Landmark",
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

              // Form
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Name (required, can be overridden)
                        CustomTextField(
                          controller: _nameController,
                          hintText: "Label",
                          prefixIcon: Icons.label,
                          fontSize: fontSize,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a label';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Dropdown: choose from presets (no manual lat/lng)
                        CustomDropdownField<LandmarkOption>(
                          value: selectedOption,
                          items: presetLocations,
                          hintText: 'Choose location (lat/lng presets)',
                          prefixIcon: Icons.map,
                          fontSize: fontSize,
                          itemLabelBuilder: (opt) => _labelForOption(opt!),
                          onChanged: (LandmarkOption? v) {
                            setState(() {
                              selectedOption = v;
                              _nameController.text = v?.label ?? '';
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // Icon selection
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Select Icon",
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              children: iconOptions.map((icon) {
                                final sel = icon == selectedIcon;
                                return GestureDetector(
                                  onTap: () => setState(() => selectedIcon = icon),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: sel ? cs.primary : cs.surface,
                                      border: Border.all(color: cs.outline.withOpacity(0.3)),
                                    ),
                                    child: Icon(icon, color: sel ? cs.onPrimary : cs.primary),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Actions
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(42),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: const Text("Back"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    if (selectedOption == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please choose a location from the dropdown')),
                                      );
                                      return;
                                    }

                                    // return result to caller (RouteOptimizationScreen)
                                    Navigator.pop(context, {
                                      "label": _nameController.text.trim(),
                                      "lat": selectedOption!.lat,
                                      "lng": selectedOption!.lng,
                                      "icon": selectedIcon,
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(42),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: const Text("Add Landmark"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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