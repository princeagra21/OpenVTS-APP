// screens/renewals/renew_device_screen.dart
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class RenewDeviceScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedDevices;

  const RenewDeviceScreen({super.key, required this.selectedDevices});

  @override
  State<RenewDeviceScreen> createState() => _RenewDeviceScreenState();
}

class _RenewDeviceScreenState extends State<RenewDeviceScreen> {
  String planStrategy = 'keep'; // 'keep' or 'override'
  String? selectedPlan;
  int? tenureMonths;
  bool alignExpiries = false;
  String collectionMethod = 'online'; // 'online', 'manual', 'upi'

  double amount = 0.0;
  double gst = 0.0;
  double total = 0.0;

  final plans = ["Annual Basic", "Annual Pro", "Half-Year Basic", "Quarterly"];
  final tenureOptions = [1, 3, 6, 12]; // Months

  final planAmounts = {
    "Annual Basic": 1499.0,
    "Annual Pro": 2499.0,
    "Half-Year Basic": 899.0,
    "Quarterly": 499.0,
  };

  final f = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _updateAmounts(); // Initialize based on first device or default
  }

  void _updateAmounts() {
    if (planStrategy == 'keep' && widget.selectedDevices.isNotEmpty) {
      // Sum amounts from selected devices (assuming they may have different plans)
      amount = widget.selectedDevices.fold(0.0, (sum, device) {
        final amtStr = device['amount'] as String;
        return sum + double.parse(amtStr.replaceAll('₹', '').replaceAll(',', ''));
      });
    } else if (planStrategy == 'override' && selectedPlan != null && tenureMonths != null) {
      // For override: base amount × tenure × number of devices
      double baseAmount = planAmounts[selectedPlan] ?? 0.0;
      amount = baseAmount * tenureMonths! * widget.selectedDevices.length;
    } else {
      amount = 499.0; // fallback
    }

    gst = amount * 0.18;
    total = amount + gst;
    setState(() {});
  }

  String _getTitle() {
    if (widget.selectedDevices.length == 1) {
      return "Renew ${widget.selectedDevices.first['vehicle']}";
    } else {
      return "Renew ${widget.selectedDevices.length} Devices";
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
        child: SingleChildScrollView(
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
                      _getTitle(),
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
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(
                        widget.selectedDevices.length == 1
                            ? "Each device has its own plan. Choose whether to keep per-device plans or override with one plan."
                            : "You have selected ${widget.selectedDevices.length} devices.",
                        style: GoogleFonts.inter(
                          fontSize: fs - 2,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
          
                // ─── PLAN STRATEGY ──────────────────────
                Text(
                  "Plan Strategy",
                  style: GoogleFonts.inter(fontSize: fs, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                  children: [
                      RadioListTile<String>(
                        title: Text("Keep device plan", style: GoogleFonts.inter(fontSize: fs - 2)),
                        subtitle: widget.selectedDevices.length > 1
                            ? Text("Each device keeps its current plan", style: GoogleFonts.inter(fontSize: fs - 4))
                            : null,
                        value: 'keep',
                        groupValue: planStrategy,
                        onChanged: (v) {
                          setState(() {
                            planStrategy = v!;
                            _updateAmounts();
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: Text("Override with one plan", style: GoogleFonts.inter(fontSize: fs - 2)),
                        subtitle: Text("Apply same plan to all selected devices", style: GoogleFonts.inter(fontSize: fs - 4)),
                        value: 'override',
                        groupValue: planStrategy,
                        onChanged: (v) {
                          setState(() {
                            planStrategy = v!;
                            _updateAmounts();
                          });
                        },
                      ),
                    ],
                  ),
                ),
          
                if (planStrategy == 'override') ...[
                  const SizedBox(height: 16),
                  StylishDropdown(
                    label: "Plan",
                    hint: "Select plan",
                    value: selectedPlan,
                    items: plans,
                    onChanged: (v) {
                      setState(() {
                        selectedPlan = v;
                        _updateAmounts();
                      });
                    },
                    width: w,
                  ),
                  const SizedBox(height: 16),
                  StylishDropdown(
                    label: "Tenure (Months)",
                    hint: "Select tenure",
                    value: tenureMonths?.toString(),
                    items: tenureOptions.map((e) => e.toString()).toList(),
                    onChanged: (v) {
                      setState(() {
                        tenureMonths = int.tryParse(v ?? '1');
                        _updateAmounts();
                      });
                    },
                    width: w,
                  ),
                ],
          
                const SizedBox(height: 16),
          
                // ─── ALIGN EXPIRIES (CO-TERM) ───────────
                SwitchListTile(
                  title: Text(
                    "Align Expiries to a single date (co-term)",
                    style: GoogleFonts.inter(fontSize: fs - 2, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Co-term will prorate shorter/longer cycles so all selected devices share one renewal date.",
                    style: GoogleFonts.inter(fontSize: fs - 4, color: cs.onSurface.withOpacity(0.7)),
                  ),
                  value: alignExpiries,
                  onChanged: widget.selectedDevices.length > 1 ? (v) => setState(() => alignExpiries = v) : null,
                ),
          
                const SizedBox(height: 16),
          
                // ─── AMOUNT BREAKDOWN ───────────────────
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
        // AMOUNT
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Amount",
                style: GoogleFonts.inter(
                  fontSize: fs - 3,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                f.format(amount),
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

        // TOTAL
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Total",
                style: GoogleFonts.inter(
                  fontSize: fs - 3,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                f.format(total),
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



          
                const SizedBox(height: 24),
          
                // ─── COLLECTION METHOD ──────────────────
                Text(
                  "Collection Method",
                  style: GoogleFonts.inter(fontSize: fs, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 4,
                   shadowColor: Colors.black.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: Text("Online Link", style: GoogleFonts.inter(fontSize: fs - 2)),
                        value: 'online',
                        groupValue: collectionMethod,
                        onChanged: (v) => setState(() => collectionMethod = v!),
                      ),
                      RadioListTile<String>(
                        title: Text("Manual Receipt", style: GoogleFonts.inter(fontSize: fs - 2)),
                        value: 'manual',
                        groupValue: collectionMethod,
                        onChanged: (v) => setState(() => collectionMethod = v!),
                      ),
                      RadioListTile<String>(
                        title: Text("UPI", style: GoogleFonts.inter(fontSize: fs - 2)),
                        value: 'upi',
                        groupValue: collectionMethod,
                        onChanged: (v) => setState(() => collectionMethod = v!),
                      ),
                    ],
                  ),
                ),
          
                if (collectionMethod == 'online') ...[
                  const SizedBox(height: 16),
                  Text(
                    "Payment Link",
                    style: GoogleFonts.inter(fontSize: fs, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          "https://pay.fleetstackglobal.com/R/O25DDH",
                          style: GoogleFonts.inter(fontSize: fs - 2, color: cs.primary),
                        ),
                      ),
                      IconButton(
                        icon:  Icon(Icons.content_copy, color: cs.primary,),
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: "https://pay.fleetstackglobal.com/R/O25DDH"));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Link copied!')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
          
                const SizedBox(height: 16),
          
                Text(
                  "In production, this creates invoices per device (or one consolidated invoice), updates each device's term, and reconciles payment.",
                  style: GoogleFonts.inter(fontSize: fs - 4, color: cs.onSurface.withOpacity(0.7)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                          // TODO: Confirm and process renewal
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(36),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.3),
                        ),
                        child: Text(
                          collectionMethod == 'online' ? "Confirm & Send Link" : "Confirm",
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
    );
  }
}

// Keep the StylishDropdown class exactly as before (reused)
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


