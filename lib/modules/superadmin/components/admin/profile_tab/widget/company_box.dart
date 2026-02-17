// components/admin/company_box.dart
import 'package:fleet_stack/modules/superadmin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_stack/core/models/admin_profile.dart';

class CompanyBox extends StatelessWidget {
  final AdminProfile? profile;
  final bool loading;

  const CompanyBox({super.key, this.profile, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth);
    final double subheaderFontSize =
        AdaptiveUtils.getTitleFontSize(screenWidth) - 2;

    const fallbackCompanyName = "Fleet Stack Global Pvt. Ltd.";
    const fallbackWebsite = "fleetstackglobal.com";
    const fallbackAddressLine = "42, Indus Tech Park";
    const fallbackCity = "Bengaluru";
    const fallbackState = "Karnataka";
    const fallbackPostal = "560001";
    const fallbackCountry = "India (IN)";
    const fallbackEmail = "aarav.sharma@fleetstackglobal.com";
    const fallbackPhone = "+91 8987675654";

    final p = profile;
    final companyName = (p != null && p.companyName.isNotEmpty)
        ? p.companyName
        : fallbackCompanyName;
    final website = (p != null && p.website.isNotEmpty)
        ? p.website
        : fallbackWebsite;
    final addressLine = (p != null && p.addressLine.isNotEmpty)
        ? p.addressLine
        : fallbackAddressLine;
    final city = (p != null && p.city.isNotEmpty) ? p.city : fallbackCity;
    final state = (p != null && p.state.isNotEmpty) ? p.state : fallbackState;
    final postal = (p != null && p.pincode.isNotEmpty)
        ? p.pincode
        : fallbackPostal;
    final country = (p != null && p.country.isNotEmpty)
        ? p.country
        : fallbackCountry;
    final email = (p != null && p.email.isNotEmpty) ? p.email : fallbackEmail;
    final phone = (p != null && p.phone.isNotEmpty) ? p.phone : fallbackPhone;

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
          // COMPANY
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "Company",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.7),
                    letterSpacing: 0.8,
                  ),
                ),
                if (loading)
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                companyName,
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
            website,
            style: GoogleFonts.inter(
              fontSize: subheaderFontSize,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),

          const SizedBox(height: 24),

          // SOCIAL MEDIA
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

          // ADDRESS
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
              _buildAddressRow(
                "Line",
                addressLine,
                subheaderFontSize,
                colorScheme,
              ),
              const SizedBox(height: 8),
              _buildAddressRow("City", city, subheaderFontSize, colorScheme),
              const SizedBox(height: 8),
              _buildAddressRow("State", state, subheaderFontSize, colorScheme),
              const SizedBox(height: 8),
              _buildAddressRow(
                "Postal",
                postal,
                subheaderFontSize,
                colorScheme,
              ),
              const SizedBox(height: 8),
              _buildAddressRow(
                "Country",
                country,
                subheaderFontSize,
                colorScheme,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // CONTACTS
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
                email,
                style: GoogleFonts.inter(
                  fontSize: subheaderFontSize,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                phone,
                style: GoogleFonts.inter(
                  fontSize: subheaderFontSize,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                website,
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

  Widget _buildAddressRow(
    String label,
    String value,
    double fontSize,
    ColorScheme colorScheme,
  ) {
    return Row(
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
    );
  }
}
