// components/admin/company_box.dart
import 'package:fleet_stack/components/small_box/small_box.dart'; // Assuming SmallTab is in small_box.dart
import 'package:fleet_stack/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CompanyBox extends StatelessWidget {
  const CompanyBox({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth); // 8/12/16
    final double titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth); // Adjust as needed
    final double subheaderFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) - 2;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(25), // Rounded corners (top and all)
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "COMPANY",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.7),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Fleet Stack Global Pvt. Ltd.",
                style: GoogleFonts.inter(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              CircleAvatar(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                child: const Text("FS"),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            "fleetstackglobal.com",
            style: GoogleFonts.inter(
              fontSize: subheaderFontSize,
              color: Colors.black.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Social Media",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.7),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SmallTab(
                label: "LinkedIn",
                selected: false,
                onTap: () {}, // Add URL launch if needed
              ),
              SmallTab(
                label: "Twitter",
                selected: false,
                onTap: () {}, // Add URL launch if needed
              ),
              SmallTab(
                label: "Facebook",
                selected: false,
                onTap: () {}, // Add URL launch if needed
              ),
              SmallTab(
                label: "Instagram",
                selected: false,
                onTap: () {}, // Add URL launch if needed
              ),
              SmallTab(
                label: "GitHub",
                selected: false,
                onTap: () {}, // Add URL launch if needed
              ),
              SmallTab(
                label: "YouTube",
                selected: false,
                onTap: () {}, // Add URL launch if needed
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "Address",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.7),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Line",
                    style: GoogleFonts.inter(fontSize: subheaderFontSize, color: Colors.black87),
                  ),
                  Text(
                    "42, Indus Tech Park",
                    style: GoogleFonts.inter(fontSize: subheaderFontSize, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "City",
                    style: GoogleFonts.inter(fontSize: subheaderFontSize, color: Colors.black87),
                  ),
                  Text(
                    "Bengaluru",
                    style: GoogleFonts.inter(fontSize: subheaderFontSize, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "State",
                    style: GoogleFonts.inter(fontSize: subheaderFontSize, color: Colors.black87),
                  ),
                  Text(
                    "Karnataka",
                    style: GoogleFonts.inter(fontSize: subheaderFontSize, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Postal",
                    style: GoogleFonts.inter(fontSize: subheaderFontSize, color: Colors.black87),
                  ),
                  Text(
                    "560001",
                    style: GoogleFonts.inter(fontSize: subheaderFontSize, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Country",
                    style: GoogleFonts.inter(fontSize: subheaderFontSize, color: Colors.black87),
                  ),
                  Text(
                    "India (IN)",
                    style: GoogleFonts.inter(fontSize: subheaderFontSize, color: Colors.black87),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "Contacts",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.7),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "aarav.sharma@fleetstackglobal.com",
                style: GoogleFonts.inter(fontSize: subheaderFontSize, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                "+91 8987675654",
                style: GoogleFonts.inter(fontSize: subheaderFontSize, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                "fleetstackglobal.com",
                style: GoogleFonts.inter(fontSize: subheaderFontSize, color: Colors.black.withOpacity(0.7)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}