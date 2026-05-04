import 'package:fleet_stack/core/models/admin_profile.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileCompanyBox extends StatelessWidget {
  final AdminProfile? profile;
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
    return parts.take(2).map((e) => e[0]).join().toUpperCase();
  }

  String _fullAddress(AdminProfile? profile) {
    if (profile == null) return '-';
    final data = profile.data;
    final addr = data['address'];
    if (addr is Map) {
      final map = addr is Map<String, dynamic>
          ? addr
          : Map<String, dynamic>.from(addr.cast());
      final direct = map['fullAddress']?.toString().trim();
      if (direct != null && direct.isNotEmpty) return direct;
      final parts = <String>[
        map['addressLine']?.toString().trim() ?? '',
        map['city']?.toString().trim() ?? map['cityName']?.toString().trim() ?? '',
        map['state']?.toString().trim() ?? map['stateName']?.toString().trim() ?? '',
        map['country']?.toString().trim() ?? map['countryName']?.toString().trim() ?? '',
        map['pincode']?.toString().trim() ?? '',
      ].where((e) => e.isNotEmpty && e != '-').toList();
      if (parts.isNotEmpty) return parts.join(', ');
    }
    final parts = <String>[
      profile.addressLine.trim(),
      profile.city.trim(),
      profile.state.trim(),
      profile.country.trim(),
      profile.pincode.trim(),
    ].where((e) => e.isNotEmpty && e != '-').toList();
    return parts.isNotEmpty ? parts.join(', ') : '-';
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
    final double subheaderFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) - 2;
    final double iconBox = 40 * (AdaptiveUtils.getTitleFontSize(screenWidth) / 14);
    final double iconSize = 18 * (AdaptiveUtils.getTitleFontSize(screenWidth) / 14);
    final double labelFs = 11 * (AdaptiveUtils.getTitleFontSize(screenWidth) / 14);
    final double titleFs = 14 * (AdaptiveUtils.getTitleFontSize(screenWidth) / 14);

    final p = profile;
    final companyName = _display(p?.companyName);
    final website = _display(p?.website);
    final address = _fullAddress(p);

    Future<void> openUrl(String url) async {
      final uri = Uri.tryParse(url);
      if (uri == null) return;
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? colorScheme.surfaceVariant
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.onSurface.withOpacity(0.12),
                  ),
                ),
                alignment: Alignment.center,
                child: loading
                    ? const AppShimmer(width: 22, height: 22, radius: 10)
                    : Text(
                        _initials(companyName),
                        style: GoogleFonts.roboto(
                          fontSize: iconSize - 2,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    loading
                        ? const AppShimmer(width: 120, height: 14, radius: 7)
                        : Text(
                            companyName,
                            style: GoogleFonts.roboto(
                              fontSize: titleFs,
                              height: 20 / 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    const SizedBox(height: 4),
                    if (loading)
                      const AppShimmer(width: 170, height: 16, radius: 7)
                    else if (website != '-') 
                      InkWell(
                        onTap: () => openUrl(website),
                        child: Text(
                          website,
                          style: GoogleFonts.roboto(
                            fontSize: labelFs,
                            height: 14 / 11,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (!loading && socialLinks.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.only(left: iconBox + 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: socialLinks.map((label) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? colorScheme.surfaceVariant
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.12),
                      ),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.roboto(
                        fontSize: labelFs,
                        height: 14 / 11,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 12),
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
                _buildAddressRow('Full', address, subheaderFontSize, colorScheme),
              ],
            ),
        ],
      ),
    );
  }
}
