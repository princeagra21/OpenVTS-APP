// screens/map/add_buffer_screen.dart
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/shared/components/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddBufferScreen extends StatefulWidget {
  final bool isRadius;
  final String initialLabel;

  const AddBufferScreen({super.key, required this.isRadius, this.initialLabel = 'Geofence'});

  @override
  State<AddBufferScreen> createState() => _AddBufferScreenState();
}

class _AddBufferScreenState extends State<AddBufferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _labelController.text = widget.initialLabel;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(w);
    final fontSize = AdaptiveUtils.getTitleFontSize(w);
    String title = widget.isRadius ? "Add Radius" : "Add Width";
    String hint = widget.isRadius ? "Radius (meters)" : "Width (meters)";

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
                    title,
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
                        // Label (required)
                        CustomTextField(
                          controller: _labelController,
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

                        // Value (radius or width)
                        CustomTextField(
                          controller: _valueController,
                          hintText: hint,
                          prefixIcon: Icons.straighten,
                          keyboardType: TextInputType.number,
                          fontSize: fontSize,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a value';
                            }
                            final num? numVal = num.tryParse(value);
                            if (numVal == null || numVal <= 0) {
                              return 'Please enter a positive number';
                            }
                            return null;
                          },
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
                                    // return result to caller
                                    Navigator.pop(context, {
                                      "label": _labelController.text.trim(),
                                      "value": double.parse(_valueController.text.trim()),
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(42),
                                  backgroundColor: cs.primary,
                                  foregroundColor: cs.onPrimary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: const Text("Save"),
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
