import 'package:fleet_stack/components/admin/documents_tab/widget/quick_overview.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';

class FileCard extends StatelessWidget {
  final String fileName;
  final String version;
  final String fileSize;
  final String type;
  final List<String> tags;
  final String uploadedDate;
  final String expiryDate;
  final String status; // "Valid", "Expiring", "Expired"

  const FileCard({
    super.key,
    required this.fileName,
    required this.version,
    required this.fileSize,
    required this.type,
    required this.tags,
    required this.uploadedDate,
    required this.expiryDate,
    required this.status,
  });

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    final s = status.toLowerCase();
    if (s.contains('valid')) return colorScheme.primary;
    if (s.contains('expiring')) return Colors.orange;
    if (s.contains('expired')) return colorScheme.error;
    return colorScheme.onSurfaceVariant;
  }

  IconData _getStatusIcon(String status) {
    final s = status.toLowerCase();
    if (s.contains('valid')) return Icons.check_circle;
    if (s.contains('expiring')) return Icons.warning;
    if (s.contains('expired')) return Icons.error;
    return Icons.help;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double subtitleFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) - 2;
    final double smallFontSize = subtitleFontSize - 2;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuickOverviewScreen(fileName: fileName),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: File name + version
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    fileName,
                    style: GoogleFonts.inter(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.7),
                      letterSpacing: 0.8,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    version,
                    style: GoogleFonts.inter(
                      fontSize: smallFontSize,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // File size
            Center(
              child: Text(
                fileSize,
                style: GoogleFonts.inter(
                  fontSize: smallFontSize,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // TYPE and TAGS row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Type
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TYPE",
                      style: GoogleFonts.inter(
                        fontSize: smallFontSize - 2,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withOpacity(0.6),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type,
                      style: GoogleFonts.inter(
                        fontSize: smallFontSize,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),

                // Tags
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "TAGS",
                      style: GoogleFonts.inter(
                        fontSize: smallFontSize - 2,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withOpacity(0.6),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tag,
                                style: GoogleFonts.inter(
                                  fontSize: smallFontSize - 2,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Uploaded & Expiry row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Uploaded: $uploadedDate",
                  style: GoogleFonts.inter(
                    fontSize: smallFontSize,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  "Expiry: $expiryDate",
                  style: GoogleFonts.inter(
                    fontSize: smallFontSize,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Status container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(status, colorScheme).withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(status),
                    size: 16,
                    color: _getStatusColor(status, colorScheme),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status,
                    style: GoogleFonts.inter(
                      fontSize: smallFontSize,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(status, colorScheme),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}