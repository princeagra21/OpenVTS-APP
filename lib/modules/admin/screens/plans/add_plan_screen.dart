// screens/plans/add_plan_screen.dart
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart' show AdaptiveUtils;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AddPlanScreen extends StatefulWidget {
  const AddPlanScreen({super.key});

  @override
  State<AddPlanScreen> createState() => _AddPlanScreenState();
}

class _AddPlanScreenState extends State<AddPlanScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _priceController.addListener(() => setState(() {}));
    _durationController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w);

    final f = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    String formattedPrice = '₹0.00';
    String formattedDuration = '0 days';
    String expiryDate = 'N/A';

    if (_priceController.text.isNotEmpty) {
      try {
        final price = double.parse(_priceController.text);
        formattedPrice = f.format(price);
      } catch (_) {}
    }

    if (_durationController.text.isNotEmpty) {
      try {
        final duration = int.parse(_durationController.text);
        formattedDuration = '$duration days';
        final currentDate = DateTime(2025, 12, 25);
        final expiry = currentDate.add(Duration(days: duration));
        expiryDate = DateFormat('MMM d, yyyy').format(expiry);
      } catch (_) {}
    }

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
                    "Add Plan",
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
                        StylishTextField(
                          label: "Plan Name",
                          hint: "e.g. Annual Basic",
                          controller: _nameController,
                          prefixIcon: Icons.label_rounded,
                          validator: (v) =>
                              v == null || v.isEmpty ? "Required" : null,
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        StylishTextField(
                          label: "Description",
                          hint: "e.g. Essential tracking",
                          controller: _descriptionController,
                          prefixIcon: Icons.description_rounded,
                          validator: (v) =>
                              v == null || v.isEmpty ? "Required" : null,
                          width: w,
                          maxLines: 3,
                        ),

                        const SizedBox(height: 16),

                        StylishTextField(
                          label: "Price (INR)",
                          hint: "e.g. 1499",
                          controller: _priceController,
                          prefixIcon: Icons.currency_rupee_rounded,
                          validator: (v) =>
                              v == null || v.isEmpty ? "Required" : null,
                          width: w,
                          keyboardType: TextInputType.number,
                        ),

                        const SizedBox(height: 16),

                        StylishTextField(
                          label: "Duration (days)",
                          hint: "e.g. 365",
                          controller: _durationController,
                          prefixIcon: Icons.calendar_today_rounded,
                          validator: (v) =>
                              v == null || v.isEmpty ? "Required" : null,
                          width: w,
                          keyboardType: TextInputType.number,
                        ),

                        const SizedBox(height: 32),

                        // ─── PREVIEW ────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Preview",
                                style: GoogleFonts.inter(
                                  fontSize: AdaptiveUtils.getTitleFontSize(w),
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Quick check before saving.",
                                style: GoogleFonts.inter(
                                  fontSize: AdaptiveUtils.getSubtitleFontSize(w) - 2,
                                  color: cs.onSurface.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cs.surfaceVariant,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _previewRow("Price", formattedPrice, cs),
                                    const SizedBox(height: 8),
                                    _previewRow("Duration", formattedDuration, cs),
                                    const SizedBox(height: 8),
                                    _previewRow("If installed today", "Expiry: $expiryDate", cs),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                                  minimumSize: const Size.fromHeight(36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  "Save Plan",
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
              const SizedBox(height: 20,)
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewRow(String label, String value, ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: cs.onSurface.withOpacity(0.8),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

/// ───────────────────────────────────────────────
/// STYLISH TEXT FIELD (UPDATED)
/// ───────────────────────────────────────────────
class StylishTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final double width;
  final TextInputType? keyboardType;
  final int? maxLines;

  const StylishTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.prefixIcon,
    this.validator,
    required this.width,
    this.keyboardType,
    this.maxLines = 1,
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
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            fillColor: cs.surface,
            filled: true,
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
      ],
    );
  }
}