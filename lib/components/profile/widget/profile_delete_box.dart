// components/profile/profile_delete_box.dart
import 'package:fleet_stack/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileDeleteBox extends StatelessWidget {
  const ProfileDeleteBox({super.key, required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double fontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final Color redColor = Colors.red;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: redColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            "Danger Zone",
            style: GoogleFonts.inter(
              fontSize: fontSize + 2,
              fontWeight: FontWeight.bold,
              color: redColor,
            ),
          ),
          const SizedBox(height: 12),

          // Description + Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "This action cannot be undone. It will permanently delete your account and remove all associated data.",
                  style: GoogleFonts.inter(
                    fontSize: fontSize,
                    color: redColor,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: onDelete,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: redColor, width: 2),
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
                    color: redColor,
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
