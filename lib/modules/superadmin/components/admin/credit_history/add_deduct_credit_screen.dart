// components/admin/credit_history/add_deduct_credit_screen.dart
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddDeductCreditScreen extends StatefulWidget {
  const AddDeductCreditScreen({super.key});

  @override
  State<AddDeductCreditScreen> createState() => _AddDeductCreditScreenState();
}

class _AddDeductCreditScreenState extends State<AddDeductCreditScreen> {
  String? _selectedAction; // 'add' or 'deduct'
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // Reusable minimal InputDecoration — similar to EditAdminProfileScreen
  InputDecoration _minimalDecoration(BuildContext context, {String? hint}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: colorScheme.onSurface.withOpacity(0.5),
        fontSize: AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIconConstraints: const BoxConstraints(minWidth: 48),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );
  }

  // Dropdown decoration
  InputDecoration _dropdownDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
    );
  }

  String get _noteHint {
    if (_selectedAction == 'add') {
      return 'Why we are adding credit';
    } else if (_selectedAction == 'deduct') {
      return 'Why we are deducting credit';
    } else {
      return 'Note (optional)';
    }
  }

  String get _confirmButtonText {
    if (_selectedAction == 'add') {
      return 'Add Credits';
    } else if (_selectedAction == 'deduct') {
      return 'Deduct Credits';
    } else {
      return 'Confirm';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w) + 6;
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(w);
    final double labelSize = AdaptiveUtils.getTitleFontSize(w);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add/Deduct Credits",
                    style: GoogleFonts.inter(
                      fontSize: titleSize + 2,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface.withOpacity(0.9),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, size: 28, color: colorScheme.onSurface.withOpacity(0.8)),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                "Manage credits",
                style: GoogleFonts.inter(
                  fontSize: labelSize - 2,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),

              const SizedBox(height: 32),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Action Dropdown
                      DropdownButtonFormField<String>(
                        isExpanded: true, // Added this to expand the dropdown to full width
                        decoration: _dropdownDecoration(context),
                        value: _selectedAction,
                        hint: Text(
                          'Select Action',
                          style: GoogleFonts.inter(
                            color: colorScheme.onSurface.withOpacity(0.5),
                            fontSize: labelSize,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'add', child: Text('Add Credit')),
                          DropdownMenuItem(value: 'deduct', child: Text('Deduct Credit')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedAction = value;
                          });
                        },
                        style: GoogleFonts.inter(fontSize: labelSize, color: colorScheme.onSurface),
                        icon: Icon(Icons.arrow_drop_down, color: colorScheme.primary),
                      ),

                      const SizedBox(height: 16),

                      // Credit Amount
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(fontSize: labelSize, color: colorScheme.onSurface),
                        decoration: _minimalDecoration(context, hint: "Credit Amount").copyWith(
                          prefixIcon: Icon(Icons.monetization_on_outlined, color: colorScheme.primary, size: 22),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Note
                      TextField(
                        controller: _noteController,
                        style: GoogleFonts.inter(fontSize: labelSize, color: colorScheme.onSurface),
                        decoration: _minimalDecoration(context, hint: _noteHint).copyWith(
                          prefixIcon: Icon(Icons.note_outlined, color: colorScheme.primary, size: 22),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    "Cancel",
                                    style: GoogleFonts.inter(
                                      fontSize: labelSize,
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                // TODO: Implement add/deduct logic based on _selectedAction, _amountController.text, _noteController.text
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    _confirmButtonText,
                                    style: GoogleFonts.inter(
                                      fontSize: labelSize,
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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