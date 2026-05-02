// components/admin/company_box.dart
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/profile_tab/edit_company_screen.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_stack/core/models/admin_profile.dart';

class CompanyBox extends StatelessWidget {
  final AdminProfile? profile;
  final bool loading;
  final VoidCallback? onUpdated;

  const CompanyBox({
    super.key,
    this.profile,
    this.loading = false,
    this.onUpdated,
  });

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
    // Other company fields are shown below via key/value rows.

    final customDomain = _valueFromKeys(p, const [
      'customDomain',
      'custom_domain',
      'domain',
      'website',
      'websiteUrl',
    ]);
    final primaryColor = _valueFromKeys(p, const [
      'primaryColor',
      'primary_color',
      'brandColor',
      'brand_color',
    ]);
    final facebook = _socialLink(p, 'facebook');
    final favicon = _valueFromKeys(p, const [
      'favicon',
      'faviconUrl',
      'favicon_url',
    ]);
    final logoLight = _valueFromKeys(p, const [
      'logoLight',
      'logo_light',
      'logoLightUrl',
      'logo_light_url',
    ]);
    final logoDark = _valueFromKeys(p, const [
      'logoDark',
      'logo_dark',
      'logoDarkUrl',
      'logo_dark_url',
    ]);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
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
                      child: Icon(
                        Icons.apartment,
                        color: colorScheme.onSurface,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Company",
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withOpacity(0.7),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          loading
                              ? const AppShimmer(width: 160, height: 18, radius: 8)
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!loading)
                InkWell(
                  onTap: p == null || onUpdated == null
                      ? null
                      : () async {
                          final updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditCompanyScreen(profile: p),
                            ),
                          );
                          if (updated == true) onUpdated?.call();
                        },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.14),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          const SizedBox(height: 10),
          _buildKeyValueRow(
            "Custom Domain",
            customDomain,
            subheaderFontSize,
            colorScheme,
          ),
          const SizedBox(height: 10),
          _buildKeyValueRow(
            "Primary Color",
            primaryColor,
            subheaderFontSize,
            colorScheme,
          ),
          const SizedBox(height: 10),
          _buildKeyValueRow(
            "Facebook",
            facebook,
            subheaderFontSize,
            colorScheme,
          ),
          const SizedBox(height: 10),
          _buildKeyValueRow(
            "Favicon",
            favicon,
            subheaderFontSize,
            colorScheme,
          ),
          const SizedBox(height: 10),
          _buildKeyValueRow(
            "Logo Light",
            logoLight,
            subheaderFontSize,
            colorScheme,
          ),
          const SizedBox(height: 10),
          _buildKeyValueRow(
            "Logo Dark",
            logoDark,
            subheaderFontSize,
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildKeyValueRow(
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
          style: GoogleFonts.roboto(
            fontSize: fontSize,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: fontSize,
              color: colorScheme.onSurface.withOpacity(0.87),
            ),
          ),
        ),
      ],
    );
  }

  String _valueFromKeys(AdminProfile? p, List<String> keys) {
    if (p == null) return '-';
    for (final key in keys) {
      final v = p.data[key];
      if (v == null) continue;
      final text = v.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '-';
  }

  String _display(String? value) {
    if (value == null) return '-';
    final text = value.trim();
    return text.isEmpty ? '-' : text;
  }

  String _socialLink(AdminProfile? p, String key) {
    if (p == null) return '-';
    final data = p.data;
    final social = data['company'] is Map ? (data['company'] as Map) : null;
    final candidates = [
      data['socialLinks'],
      social is Map ? social['socialLinks'] : null,
      data[key],
      social is Map ? social[key] : null,
    ];
    for (final candidate in candidates) {
      if (candidate is Map) {
        final map = candidate is Map<String, dynamic>
            ? candidate
            : Map<String, dynamic>.from(candidate.cast());
        final v = map[key] ?? map[key.toLowerCase()];
        if (v != null) {
          final text = v.toString().trim();
          if (text.isNotEmpty) return text;
        }
      } else if (candidate != null) {
        final text = candidate.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }
    return '-';
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
