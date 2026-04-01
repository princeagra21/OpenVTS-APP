import 'package:fleet_stack/core/models/superadmin_profile.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileCompanyBox extends StatelessWidget {
  final SuperadminProfile? profile;
  final bool loading;
  final List<String> socialLinks;

  const ProfileCompanyBox({
    super.key,
    this.profile,
    this.loading = false,
    this.socialLinks = const <String>[],
  });

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

  Widget _buildAddressRow(
    String label,
    String value,
    double fontSize,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: fontSize,
              color: colorScheme.onSurface.withOpacity(0.87),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                fontSize: fontSize,
                color: colorScheme.onSurface.withOpacity(0.87),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          Text(
            'Company',
            style: GoogleFonts.roboto(
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
              Expanded(
                child: loading
                    ? const AppShimmer(
                        width: double.infinity,
                        height: 22,
                        radius: 8,
                      )
                    : Text(
                        companyName,
                        style: GoogleFonts.roboto(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              const SizedBox(width: 8),
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
              ? const AppShimmer(width: 170, height: 16, radius: 8)
              : Text(
                  website,
                  style: GoogleFonts.roboto(
                    fontSize: subheaderFontSize,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),

          const SizedBox(height: 24),
          Text(
            'Social Media',
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.7),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          if (loading)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                AppShimmer(width: 84, height: 30, radius: 12),
                AppShimmer(width: 72, height: 30, radius: 12),
                AppShimmer(width: 88, height: 30, radius: 12),
              ],
            )
          else if (socialLinks.isEmpty)
            Text(
              'No social links from API.',
              style: GoogleFonts.roboto(
                fontSize: subheaderFontSize,
                color: colorScheme.onSurface.withOpacity(0.65),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: socialLinks
                  .map((label) => SmallTab(label: label, selected: false))
                  .toList(),
            ),

          const SizedBox(height: 24),
          Text(
            'Address',
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.7),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          if (loading)
            const Column(
              children: [
                AppShimmer(width: double.infinity, height: 16, radius: 8),
                SizedBox(height: 8),
                AppShimmer(width: double.infinity, height: 16, radius: 8),
                SizedBox(height: 8),
                AppShimmer(width: double.infinity, height: 16, radius: 8),
                SizedBox(height: 8),
                AppShimmer(width: double.infinity, height: 16, radius: 8),
                SizedBox(height: 8),
                AppShimmer(width: double.infinity, height: 16, radius: 8),
              ],
            )
          else
            Column(
              children: [
                _buildAddressRow(
                  'Line',
                  addressLine,
                  subheaderFontSize,
                  colorScheme,
                ),
                _buildAddressRow('City', city, subheaderFontSize, colorScheme),
                _buildAddressRow(
                  'State',
                  state,
                  subheaderFontSize,
                  colorScheme,
                ),
                _buildAddressRow(
                  'Postal',
                  postal,
                  subheaderFontSize,
                  colorScheme,
                ),
                _buildAddressRow(
                  'Country',
                  country,
                  subheaderFontSize,
                  colorScheme,
                ),
              ],
            ),

          const SizedBox(height: 24),
          Text(
            'Contacts',
            style: GoogleFonts.roboto(
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
                      style: GoogleFonts.roboto(
                        fontSize: subheaderFontSize,
                        color: colorScheme.onSurface.withOpacity(0.87),
                      ),
                    ),
              const SizedBox(height: 8),
              loading
                  ? const AppShimmer(width: 220, height: 16, radius: 8)
                  : Text(
                      phone,
                      style: GoogleFonts.roboto(
                        fontSize: subheaderFontSize,
                        color: colorScheme.onSurface.withOpacity(0.87),
                      ),
                    ),
              const SizedBox(height: 8),
              loading
                  ? const AppShimmer(width: 170, height: 16, radius: 8)
                  : Text(
                      website,
                      style: GoogleFonts.roboto(
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
}
