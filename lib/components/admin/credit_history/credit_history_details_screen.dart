import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';

class CreditHistoryDetailsScreen extends StatelessWidget {
  final String date;
  final String description;
  final String amount;
  final String balance;

  const CreditHistoryDetailsScreen({
    super.key,
    required this.date,
    required this.description,
    required this.amount,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;

    final double padding = AdaptiveUtils.getHorizontalPadding(w) + 6;
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(w);
    final double contentSize = AdaptiveUtils.getTitleFontSize(w) + 1;
    final double nmlFontSize = AdaptiveUtils.getTitleFontSize(w);
    final double FontSize = AdaptiveUtils.getTitleFontSize(w) + 3;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            children: [

              // ---------- AVATAR + CLOSE BUTTON ----------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                    child: Center(
                      child: Text(
                        "FS",
                        style: GoogleFonts.inter(
                          fontSize: FontSize + 3,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 26),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // ---------- AMOUNT CENTERED ----------
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    amount,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: amount.startsWith('+') ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Successful",
                    style: GoogleFonts.inter(
                      fontSize: FontSize,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: GoogleFonts.inter(
                      fontSize: nmlFontSize,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),
              const Divider(height: 1, thickness: 1),

              const SizedBox(height: 16),

              // ---------- DESCRIPTION & BALANCE ROW ----------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: contentSize,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    balance,
                    style: GoogleFonts.inter(
                      fontSize: contentSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // ---------- DOUBLE BUTTONS ----------
              Column(
                children: [
                  _infinityButton(
                    text: "Download",
                    onTap: () {},
                    fontSize: titleSize,
                  ),
             //     const SizedBox(height: 12),
               //   _infinityButton(
               //     text: "Download PDF",
                 //   onTap: () {},
                   // fontSize: titleSize,
                //  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------ INFINITY BUTTON ------------------
  Widget _infinityButton({
    required String text,
    required VoidCallback onTap,
    required double fontSize,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
