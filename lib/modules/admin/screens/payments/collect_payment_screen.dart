// screens/payments/collect_payment_screen.dart
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class CollectPaymentScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedDevices; // List of selected devices, e.g., [{'vehicle': 'DL01EF9876', 'imei': '86348204027902', ...}]

  const CollectPaymentScreen({super.key, required this.selectedDevices});

  @override
  State<CollectPaymentScreen> createState() => _CollectPaymentScreenState();
}

class _CollectPaymentScreenState extends State<CollectPaymentScreen> {
  final _formKey = GlobalKey<FormState>();

  String paymentMethod = 'Cheque'; // Default to Cheque as mentioned
  final methods = ["Cheque", "Cash", "Bank Transfer", "Other"];

  // Per-device data: amount split and attached receipt file
  late List<Map<String, dynamic>> devicePayments;

  double totalAmount = 0.0;
  double gst = 0.0;
  double grandTotal = 0.0;

  final f = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    // Initialize per-device payments
    devicePayments = widget.selectedDevices.map((device) {
      return {
        'device': device,
        'amount': 0.0,
        'receiptFile': null as File?,
      };
    }).toList();
  }

  void _updateTotals() {
    totalAmount = devicePayments.fold(0.0, (sum, dp) => sum + (dp['amount'] as double));
    gst = totalAmount * 0.18;
    grandTotal = totalAmount + gst;
    setState(() {});
  }

  Future<void> _attachReceipt(int index) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        devicePayments[index]['receiptFile'] = File(result.files.single.path!);
      });
    }
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
                    "Collect Payment",
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
              Center(
                child: Text(
                  "Record an offline/manual payment across selected devices.",
                  style: GoogleFonts.inter(
                    fontSize: fs - 2,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ─── FORM ───────────────────────────────
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        StylishDropdown(
                          label: "Payment Method",
                          hint: "Select method",
                          value: paymentMethod,
                          items: methods,
                          onChanged: (v) => setState(() => paymentMethod = v ?? 'Cheque'),
                          width: w,
                        ),

                        const SizedBox(height: 24),

                        // ─── PER-DEVICE ALLOCATION ──────────────
                        ...devicePayments.asMap().entries.map((entry) {
                          final dp = entry.value;

                       return  Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      // AMOUNT FIELD
      StylishTextField(
        label: "Amount",
        hint: "Enter amount for this device",
        controller: TextEditingController(
          text: f.format(dp['amount']),
        ),
        prefixIcon: Icons.currency_rupee_rounded,
        validator: (v) => v == null || v.isEmpty ? "Required" : null,
        width: w,
        onChanged: (v) {
          dp['amount'] =
              double.tryParse(v.replaceAll('₹', '').replaceAll(',', '')) ??
                  0.0;
          _updateTotals();
        },
      ),

      const SizedBox(height: 12),

      // TXN / CHEQUE / REF FIELD
      StylishTextField(
        label: "Txn / Cheque / Ref No",
        hint: "Enter transaction reference",
        prefixIcon: Icons.receipt_long_rounded,
        width: w,
        onChanged: (v) {
          dp['reference'] = v;
        },
      ),
    ],
  ),
);

                        }),

                        const SizedBox(height: 16),

                        // ─── TOTAL BREAKDOWN ────────────────────
                        Card(
  elevation: 4,
  shadowColor: Colors.black.withOpacity(0.3),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Row(
      children: [
        // TOTAL AMOUNT
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total Amount",
                style: GoogleFonts.inter(
                  fontSize: fs - 3,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                f.format(totalAmount),
                style: GoogleFonts.inter(
                  fontSize: fs,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // GST
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "GST (18%)",
                style: GoogleFonts.inter(
                  fontSize: fs - 3,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                f.format(gst),
                style: GoogleFonts.inter(
                  fontSize: fs,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // GRAND TOTAL
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Grand Total",
                style: GoogleFonts.inter(
                  fontSize: fs - 3,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                f.format(grandTotal),
                style: GoogleFonts.inter(
                  fontSize: fs,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
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
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  side: BorderSide(color: cs.primary.withOpacity(0.3)),
                                  foregroundColor: cs.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Text(
                                  "Cancel",
                                  style: GoogleFonts.inter(fontSize: fs, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    // SUBMIT LOGIC: Save payment, update devices, etc.
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 4,
                                  shadowColor: Colors.black.withOpacity(0.3),
                                ),
                                child: Text(
                                  "Save Payment",
                                  style: GoogleFonts.inter(fontSize: fs, fontWeight: FontWeight.w600),
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// ───────────────────────────────────────────────
/// STYLISH TEXT FIELD (Reused)
/// ───────────────────────────────────────────────
class StylishTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final double width;
  final ValueChanged<String>? onChanged;

  const StylishTextField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    required this.prefixIcon,
    this.validator,
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
    color: cs.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: cs.outline.withOpacity(0.4), // subtle border
      width: 1,
    ),
  ),

  child: TextFormField(
    controller: controller,
    validator: validator,
    onChanged: onChanged,
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
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
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
/// STYLISH DROPDOWN (Reused)
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
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            iconEnabledColor: cs.primary,
            iconDisabledColor: cs.primary,
            value: value,
            hint: Text(
              hint,
              style: GoogleFonts.inter(
                color: cs.onSurface.withOpacity(0.6),
                fontSize: fs,
              ),
            ),
            decoration: InputDecoration(
              fillColor: cs.surface,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}