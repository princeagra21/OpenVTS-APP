// components/admin/delete_account_box.dart
import 'package:fleet_stack/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeleteAccountBox extends StatelessWidget {
  const DeleteAccountBox({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double fontSize = AdaptiveUtils.getTitleFontSize(screenWidth);

    // Semantic error color — works perfectly in light & dark mode
    final Color dangerColor = colorScheme.error;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: dangerColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Danger Zone",
            style: GoogleFonts.inter(
              fontSize: fontSize + 2,
              fontWeight: FontWeight.bold,
              color: dangerColor,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "This action cannot be undone. It will permanently delete the user account and remove all associated data.",
                  style: GoogleFonts.inter(
                    fontSize: fontSize,
                    color: dangerColor,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  // TODO: Add delete confirmation dialog
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: dangerColor, width: 2),
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: padding * 2,
                    vertical: padding,
                  ),
                ),
                child: Text(
                  "Delete",
                  style: GoogleFonts.inter(
                    fontSize: fontSize,
                    color: dangerColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}