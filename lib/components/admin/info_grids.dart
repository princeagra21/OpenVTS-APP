// components/admin/admin_info_boxes.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/adaptive_utils.dart'; // Our shared adaptive utils

class AdminInfoBoxes extends StatelessWidget {
  const AdminInfoBoxes({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    // Fully adaptive values from AdaptiveUtils
    final double horizontalPadding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2; // 12–16
    final double contentFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) + 1;   // 12–14

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: horizontalPadding,
      mainAxisSpacing: horizontalPadding,
      childAspectRatio: 1.5,
      children: [
        _buildInfoBox(
          title: "Vehicles",
          content: "512",
          titleFontSize: titleFontSize,
          contentFontSize: contentFontSize,
          padding: horizontalPadding,
        ),
        _buildInfoBox(
          title: "Credits",
          content: "12,000",
          titleFontSize: titleFontSize,
          contentFontSize: contentFontSize,
          padding: horizontalPadding,
        ),
        _buildInfoBox(
          title: "Last Login",
          content: "20 Nov 2025, 7:30pm\n17 hours ago",
          titleFontSize: titleFontSize,
          contentFontSize: contentFontSize,
          padding: horizontalPadding,
        ),
        _buildInfoBox(
          title: "Created",
          content: "10 Sept 2025",
          titleFontSize: titleFontSize,
          contentFontSize: contentFontSize,
          padding: horizontalPadding,
        ),
      ],
    );
  }

  Widget _buildInfoBox({
    required String title,
    required String content,
    required double titleFontSize,
    required double contentFontSize,
    required double padding,
  }) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
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
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
}