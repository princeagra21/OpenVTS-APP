import 'package:fleet_stack/core/models/admin_profile.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/profile_tab/edit_company_screen.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final double fs = AdaptiveUtils.getSubtitleFontSize(screenWidth);
    final double scale = fs / 14;
    final double labelFs = 11 * scale;
    final double titleFs = 14 * scale;
    final double iconBox = 40 * scale;
    final double iconSize = 18 * scale;

    final data = profile?.data ?? const <String, dynamic>{};
    final company = _extractCompanyMap(data);

    final companyName = _safe(
      (company['name'] ?? profile?.companyName ?? '').toString(),
    );
    final websiteUrl = _safe(
      (company['websiteUrl'] ??
              company['customDomain'] ??
              data['websiteUrl'] ??
              data['customDomain'] ??
              '')
          .toString(),
    );
    final socialLinks = _companySocialLinks(data, company);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                child: Icon(
                  Icons.apartment,
                  size: iconSize,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company',
                      style: GoogleFonts.roboto(
                        fontSize: labelFs,
                        height: 14 / 11,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    loading
                        ? const AppShimmer(width: 180, height: 18, radius: 8)
                        : Text(
                            companyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              fontSize: titleFs,
                              height: 20 / 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                    if (!loading && websiteUrl != '-') ...[
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _openExternalLink(websiteUrl),
                        child: Text(
                          websiteUrl,
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
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: profile == null || onUpdated == null
                    ? null
                    : () async {
                        final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditCompanyScreen(profile: profile!),
                          ),
                        );
                        if (updated == true) onUpdated?.call();
                      },
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
          if (!loading && socialLinks.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.only(left: iconBox + 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: socialLinks
                    .map(
                      (link) => InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _openExternalLink(link.url),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
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
                            link.label,
                            style: GoogleFonts.roboto(
                              fontSize: labelFs,
                              height: 14 / 11,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openExternalLink(String rawUrl) async {
    final value = rawUrl.trim();
    if (value.isEmpty || value == '-') return;
    final normalized =
        value.startsWith('http://') || value.startsWith('https://')
        ? value
        : 'https://$value';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Map<String, dynamic> _extractCompanyMap(Map<String, dynamic> data) {
    final companies = data['companies'];
    if (companies is List && companies.isNotEmpty && companies.first is Map) {
      return Map<String, dynamic>.from((companies.first as Map).cast());
    }
    if (data['company'] is Map) {
      return Map<String, dynamic>.from((data['company'] as Map).cast());
    }
    return const <String, dynamic>{};
  }

  List<_CompanyLink> _companySocialLinks(
    Map<String, dynamic> data,
    Map<String, dynamic> company,
  ) {
    final links = <_CompanyLink>[];

    void addLink(String label, Object? value) {
      final v = (value?.toString() ?? '').trim();
      if (v.isEmpty || v == '-') return;
      if (links.any((e) => e.url == v)) return;
      links.add(_CompanyLink(label: label, url: v));
    }

    final social = company['socialLinks'] ?? data['socialLinks'];
    if (social is Map) {
      for (final e in social.entries) {
        addLink(_titleCaseKey(e.key.toString()), e.value);
      }
    }

    return links;
  }

  String _titleCaseKey(String key) {
    final cleaned = key.replaceAll(RegExp(r'[_\\-]+'), ' ').trim();
    if (cleaned.isEmpty) return key;
    return cleaned
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) => part.substring(0, 1).toUpperCase() + part.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  String _safe(String? value) {
    final text = (value ?? '').trim();
    return text.isEmpty ? '—' : text;
  }
}

class _CompanyLink {
  final String label;
  final String url;
  const _CompanyLink({required this.label, required this.url});
}
