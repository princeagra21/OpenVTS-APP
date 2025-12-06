// components/profile/profile_info_boxes.dart
import 'package:fleet_stack/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileInfoBoxes extends StatelessWidget {
  const ProfileInfoBoxes({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final double horizontalPadding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double contentFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) + 1;

    return Row(
      children: [
        Expanded(
          child: _buildInfoBox(
            context: context,
            title: "Last Login",
            content: "20 Nov 2025, 7:30pm\n17 hours ago",
            titleFontSize: titleFontSize,
            contentFontSize: contentFontSize,
            padding: horizontalPadding,
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
          ),
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
  }) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              content,
              style: GoogleFonts.inter(
                fontSize: contentFontSize,
                color: Colors.black.withOpacity(0.6),
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
