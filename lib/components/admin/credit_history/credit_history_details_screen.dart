// components/admin/credit_history/credit_history_details_screen.dart
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
    final colorScheme = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;

    final double padding = AdaptiveUtils.getHorizontalPadding(w) + 6;
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(w);
    final double contentSize = AdaptiveUtils.getTitleFontSize(w) + 1;
    final double nmlFontSize = AdaptiveUtils.getTitleFontSize(w);
    final double largeFontSize = AdaptiveUtils.getTitleFontSize(w) + 3;

    final bool isPositive = amount.startsWith('+');
    final Color amountColor = isPositive ? colorScheme.primary : colorScheme.error;

    return Scaffold(
      backgroundColor: colorScheme.background,
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
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary,
                    ),
                    child: Center(
                      child: Text(
                        "FS",
                        style: GoogleFonts.inter(
                          fontSize: largeFontSize + 3,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),

                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, size: 26, color: colorScheme.onSurface),
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
                      color: amountColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Successful",
                    style: GoogleFonts.inter(
                      fontSize: largeFontSize,
                      color: colorScheme.onSurface.withOpacity(0.54),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: GoogleFonts.inter(
                      fontSize: nmlFontSize,
                      color: colorScheme.onSurface.withOpacity(0.45),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),
              Divider(height: 1, thickness: 1, color: colorScheme.onSurface.withOpacity(0.1)),

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
                        color: colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    balance,
                    style: GoogleFonts.inter(
                      fontSize: contentSize,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // ---------- ACTION BUTTON ----------
              _infinityButton(
                context,
                text: "Download",
                onTap: () {},
                fontSize: titleSize,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  // ------------------ INFINITY BUTTON ------------------
    Widget _infinityButton(BuildContext context, {
      required String text,
      required VoidCallback onTap,
      required double fontSize,
    }) {
      final colorScheme = Theme.of(context).colorScheme;
  
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: fontSize,
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }
  }
