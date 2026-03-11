// components/admin/company_box.dart
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
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

    final p = profile;
    final companyName = _display(p?.companyName);
    final website = _display(p?.website);
    final addressLine = _display(p?.addressLine);
    final city = _display(p?.city);
    final state = _display(p?.state);
    final postal = _display(p?.pincode);
    final country = _display(p?.country);
    final email = _display(p?.email);
    final phone = _display(p?.phone);

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
                      child: AppShimmer(width: 14, height: 14, radius: 7),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: loading
                    ? const AppShimmer(
                        width: double.infinity,
                        height: 22,
                        radius: 8,
                      )
                    : Text(
                        companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                radius: 20,
                child: Text(_initials(companyName)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          loading
              ? const AppShimmer(width: 180, height: 16, radius: 8)
              : Text(
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
                loading,
              ),
              const SizedBox(height: 8),
              _buildAddressRow(
                "City",
                city,
                subheaderFontSize,
                colorScheme,
                loading,
              ),
              const SizedBox(height: 8),
              _buildAddressRow(
                "State",
                state,
                subheaderFontSize,
                colorScheme,
                loading,
              ),
              const SizedBox(height: 8),
              _buildAddressRow(
                "Postal",
                postal,
                subheaderFontSize,
                colorScheme,
                loading,
              ),
              const SizedBox(height: 8),
              _buildAddressRow(
                "Country",
                country,
                subheaderFontSize,
                colorScheme,
                loading,
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
              loading
                  ? const AppShimmer(
                      width: double.infinity,
                      height: 16,
                      radius: 8,
                    )
                  : Text(
                      email,
                      style: GoogleFonts.inter(
                        fontSize: subheaderFontSize,
                        color: colorScheme.onSurface.withOpacity(0.87),
                      ),
                    ),
              const SizedBox(height: 8),
              loading
                  ? const AppShimmer(width: 220, height: 16, radius: 8)
                  : Text(
                      phone,
                      style: GoogleFonts.inter(
                        fontSize: subheaderFontSize,
                        color: colorScheme.onSurface.withOpacity(0.87),
                      ),
                    ),
              const SizedBox(height: 8),
              loading
                  ? const AppShimmer(width: 180, height: 16, radius: 8)
                  : Text(
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
    bool loading,
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
        Flexible(
          child: loading
              ? const Align(
                  alignment: Alignment.centerRight,
                  child: AppShimmer(width: 120, height: 14, radius: 8),
                )
              : Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: fontSize,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
        ),
      ],
    );
  }

  String _display(String? value) {
    if (value == null) return '-';
    final text = value.trim();
    return text.isEmpty ? '-' : text;
  }

  String _initials(String value) {
    final clean = _display(value);
    if (clean == '-') return '--';
    final parts = clean
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '--';
    final out = parts.take(2).map((e) => e[0]).join();
    return out.toUpperCase();
  }
}
