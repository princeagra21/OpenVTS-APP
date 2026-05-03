// components/profile/profile_company_box.dart
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileCompanyBox extends StatelessWidget {
  const ProfileCompanyBox({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth);
    final double subheaderFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) - 2;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
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
          // Company Section
          Text(
            "Company",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.7),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Open VTS Global Pvt. Ltd.",
                style: GoogleFonts.inter(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              CircleAvatar(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                radius: 20,
                child: const Text("FS"),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            "fleetstackglobal.com",
            style: GoogleFonts.inter(
              fontSize: subheaderFontSize,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),

          const SizedBox(height: 24),

          // Social Media Section
          Text(
            "Social Media",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.7),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SmallTab(label: "LinkedIn", selected: false, onTap: () {}),
              SmallTab(label: "Twitter", selected: false, onTap: () {}),
              SmallTab(label: "Facebook", selected: false, onTap: () {}),
              SmallTab(label: "Instagram", selected: false, onTap: () {}),
              SmallTab(label: "GitHub", selected: false, onTap: () {}),
              SmallTab(label: "YouTube", selected: false, onTap: () {}),
            ],
          ),

          const SizedBox(height: 24),

          // Address Section
          Text(
            "Address",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.7),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              _buildAddressRow("Line", "42, Indus Tech Park", subheaderFontSize, colorScheme),
              _buildAddressRow("City", "Bengaluru", subheaderFontSize, colorScheme),
              _buildAddressRow("State", "Karnataka", subheaderFontSize, colorScheme),
              _buildAddressRow("Postal", "560001", subheaderFontSize, colorScheme),
              _buildAddressRow("Country", "India (IN)", subheaderFontSize, colorScheme),
            ],
          ),

          const SizedBox(height: 24),

          // Contact Section
          Text(
            "Contacts",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.7),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "aarav.sharma@fleetstackglobal.com",
                style: GoogleFonts.inter(
                  fontSize: subheaderFontSize,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "+91 8987675654",
                style: GoogleFonts.inter(
                  fontSize: subheaderFontSize,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "fleetstackglobal.com",
                style: GoogleFonts.inter(
                  fontSize: subheaderFontSize,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow(String label, String value, double fontSize, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              color: colorScheme.onSurface.withOpacity(0.87),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              color: colorScheme.onSurface.withOpacity(0.87),
            ),
          ),
        ],
      ),
    );
  }
}