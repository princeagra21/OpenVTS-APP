import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsProfileCompanyCard extends StatelessWidget {
  const SettingsProfileCompanyCard({
    super.key,
    required this.companyName,
    required this.companyWebsite,
    required this.companyId,
    required this.primaryColor,
    required this.customDomain,
    required this.socialLabels,
    required this.socialLinks,
    required this.loading,
    required this.onEditCompany,
  });

  final String companyName;
  final String companyWebsite;
  final String companyId;
  final String primaryColor;
  final String customDomain;
  final List<String> socialLabels;
  final Map<String, dynamic> socialLinks;
  final bool loading;
  final VoidCallback onEditCompany;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final fs = AdaptiveUtils.getTitleFontSize(width);
    final scale2 = fs / 14;
    final labelFs = 11 * scale2;
    final titleFs = 14 * scale2;
    final iconBox = 40 * scale2;
    final iconSize = 18 * scale2;

    String? socialUrl(String label) {
      final key = label.toLowerCase().replaceAll(' ', '');
      final byKey = socialLinks[key]?.toString();
      if (byKey != null && byKey.trim().isNotEmpty) return byKey;
      for (final entry in socialLinks.entries) {
        if (entry.key.toString().toLowerCase() == key) {
          final value = entry.value?.toString() ?? '';
          if (value.trim().isNotEmpty) return value;
        }
      }
      return null;
    }

    Future<void> openUrl(String url) async {
      final uri = Uri.tryParse(url);
      if (uri == null) return;
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? cs.surfaceContainerHighest
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.apartment, size: iconSize, color: cs.onSurface),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company',
                      style: AppFonts.roboto(
                        fontSize: labelFs,
                        height: 14 / 11,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    loading
                        ? const AppShimmer(width: 180, height: 18, radius: 8)
                        : Text(
                            companyName,
                            style: AppFonts.roboto(
                              fontSize: titleFs,
                              height: 20 / 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                    if (!loading && companyWebsite != '-') ...[
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => openUrl(companyWebsite),
                        child: Text(
                          companyWebsite,
                          style: AppFonts.roboto(
                            fontSize: labelFs,
                            height: 14 / 11,
                            fontWeight: FontWeight.w500,
                            color: cs.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!loading) ...[
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onEditCompany,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.primary.withValues(alpha: 0.14)),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.edit_outlined, size: 18, color: cs.primary),
                  ),
                ),
              ],
            ],
          ),
          if (!loading && socialLabels.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.only(left: iconBox + 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: socialLabels.map((label) {
                  final url = socialUrl(label);
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: url == null ? null : () => openUrl(url),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? cs.surfaceContainerHighest
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: cs.onSurface.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text(
                        label,
                        style: AppFonts.roboto(
                          fontSize: labelFs,
                          height: 14 / 11,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
