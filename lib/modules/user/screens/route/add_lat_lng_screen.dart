// screens/map/add_lat_lng_screen.dart
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/shared/components/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

class AddLatLngScreen extends StatefulWidget {
  final LatLng? initialPoint; // optional prefill

  const AddLatLngScreen({super.key, this.initialPoint});

  @override
  State<AddLatLngScreen> createState() => _AddLatLngScreenState();
}

class _AddLatLngScreenState extends State<AddLatLngScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  IconData selectedIcon = Icons.location_on;

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
    if (widget.initialPoint != null) {
      _latController.text = widget.initialPoint!.latitude.toString();
      _lngController.text = widget.initialPoint!.longitude.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

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
                    "Add Lat/Lng",
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
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.manual,
                    child: Column(
                      children: [
                        // Name (required)
                        CustomTextField(
                          controller: _nameController,
                          hintText: "Label (e.g. Office)",
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

                        // Latitude
                        CustomTextField(
                          controller: _latController,
                          hintText: "Latitude",
                          prefixIcon: Icons.map,
                          fontSize: fontSize,
                          keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter latitude';
                            final lat = double.tryParse(value);
                            if (lat == null || lat.abs() > 90) return 'Invalid latitude (-90 to 90)';
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Longitude
                        CustomTextField(
                          controller: _lngController,
                          hintText: "Longitude",
                          prefixIcon: Icons.map_outlined,
                          fontSize: fontSize,
                          keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter longitude';
                            final lng = double.tryParse(value);
                            if (lng == null || lng.abs() > 180) return 'Invalid longitude (-180 to 180)';
                            return null;
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
                                      border: Border.all(
                                        color: cs.outline.withValues(alpha: 0.3),
                                      ),
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  foregroundColor: cs.primary,
                                  side: BorderSide(color: cs.primary),
                                ),
                                child: const Text("Back"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    final lat = double.parse(_latController.text);
                                    final lng = double.parse(_lngController.text);
                                    final label = _nameController.text.trim();

                                    // return result to caller (RouteOptimizationScreen)
                                    Navigator.pop(context, {
                                      "label": label,
                                      "lat": lat,
                                      "lng": lng,
                                      "icon": selectedIcon,
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(42),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  backgroundColor: cs.primary,
                                  foregroundColor: cs.onPrimary,
                                ),
                                child: const Text("Add Location"),
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
