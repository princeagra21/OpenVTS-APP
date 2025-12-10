// components/admin/admin_info_boxes.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';

class AdminInfoBoxes extends StatelessWidget {
  const AdminInfoBoxes({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    // Adaptive values
    final double horizontalPadding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double contentFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) + 1;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoBox(
                context: context,
                title: "Vehicles",
                content: "512",
                titleFontSize: titleFontSize,
                contentFontSize: contentFontSize,
                padding: horizontalPadding,
                colorScheme: colorScheme,
              ),
            ),
            SizedBox(width: horizontalPadding),
            Expanded(
              child: _buildInfoBox(
                context: context,
                title: "Credits",
                content: "12,000",
                titleFontSize: titleFontSize,
                contentFontSize: contentFontSize,
                padding: horizontalPadding,
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildInfoBox(
                context: context,
                title: "Last Login",
                content: "20 Nov 2025, 7:30pm\n17 hours ago",
                titleFontSize: titleFontSize,
                contentFontSize: contentFontSize,
                padding: horizontalPadding,
                colorScheme: colorScheme,
              ),
            ),
            SizedBox(width: horizontalPadding),
            Expanded(
              child: _buildInfoBox(
                context: context,
                title: "Created",
                content: "10 Sept 2025",
                titleFontSize: titleFontSize,
                contentFontSize: contentFontSize,
                padding: horizontalPadding,
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoBox({
    required BuildContext context,
    required String title,
    required String content,
    required double titleFontSize,
    required double contentFontSize,
    required double padding,
    required ColorScheme colorScheme,
  }) {
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
      height: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              content,
              style: GoogleFonts.inter(
                fontSize: contentFontSize,
                color: colorScheme.onSurface.withOpacity(0.6),
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}