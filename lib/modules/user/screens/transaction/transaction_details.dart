// screens/transactions/transaction_details_screen.dart
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final String transactionId;

  const TransactionDetailsScreen({super.key, required this.transactionId});

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Transaction Details",
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
              SizedBox(height: 24),
              Text("Status", style: GoogleFonts.inter(fontSize: fs - 2, color: cs.onSurface.withOpacity(0.6))),
              Text("success", style: GoogleFonts.inter(fontSize: fs + 4, fontWeight: FontWeight.bold, color: Colors.green)),
              SizedBox(height: 16),
              Text("Method", style: GoogleFonts.inter(fontSize: fs - 2, color: cs.onSurface.withOpacity(0.6))),
              Text("UPI", style: GoogleFonts.inter(fontSize: fs, fontWeight: FontWeight.bold)),
              SizedBox(height: 24),
              Text("Amount & Credits", style: GoogleFonts.inter(fontSize: fs, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              _detailRow("Amount", "₹14,990.00", fs, cs),
              _detailRow("Gateway fee", "₹75.00", fs, cs),
              _detailRow("Tax", "₹270.00", fs, cs),
              _detailRow("Credits", "+10", fs, cs),
              SizedBox(height: 24),
              Text("Gateway", style: GoogleFonts.inter(fontSize: fs, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Row(
                children: [
                  Text("Reference: upi://pay/intent_9A7B", style: GoogleFonts.inter(fontSize: fs - 2)),
                  IconButton(
                    icon: Icon(Icons.content_copy, color: cs.primary,),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: "upi://pay/intent_9A7B"));
                    },
                  ),
                ],
              ),
              Text("Invoice: INV-2025-0101", style: GoogleFonts.inter(fontSize: fs - 2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, double fs, ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: fs - 2, color: cs.onSurface.withOpacity(0.8))),
          Text(value, style: GoogleFonts.inter(fontSize: fs - 2, fontWeight: FontWeight.bold, color: cs.onSurface)),
        ],
      ),
    );
  }
}