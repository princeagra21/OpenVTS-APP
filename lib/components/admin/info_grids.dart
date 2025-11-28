import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminInfoBoxes extends StatelessWidget {
  const AdminInfoBoxes({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 420;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildInfoBox(
          title: "Vehicles",
          content: "512",
          isSmallScreen: isSmallScreen,
        ),
        _buildInfoBox(
          title: "Credits",
          content: "12000",
          isSmallScreen: isSmallScreen,
        ),
        _buildInfoBox(
          title: "Last Login",
          content: "20 Nov 2025, 7:30pm\n17 hours ago",
          isSmallScreen: isSmallScreen,
        ),
        _buildInfoBox(
          title: "Created",
          content: "10 Sept 2025",
          isSmallScreen: isSmallScreen,
        ),
      ],
    );
  }

  Widget _buildInfoBox({
    required String title,
    required String content,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              content,
              style: GoogleFonts.inter(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.black.withOpacity(0.6),
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