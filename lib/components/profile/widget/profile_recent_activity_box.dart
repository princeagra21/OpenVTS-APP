// components/profile/profile_recent_activity_box.dart
import 'package:fleet_stack/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileRecentActivityBox extends StatelessWidget {
  const ProfileRecentActivityBox({super.key});

  final List<Map<String, String>> activities = const [
    {
      'title': 'Created new admin account',
      'time': '2 hours ago',
      'subtitle': 'Admin: Priya Patel',
    },
    {
      'title': 'System configuration updated',
      'time': '5 hours ago',
      'subtitle': 'Updated currency settings',
    },
    {
      'title': 'Approved vehicle registration',
      'time': '1 day ago',
      'subtitle': 'VIN 9BG116GW04C400001',
    },
    {
      'title': 'Generated system report',
      'time': '2 days ago',
      'subtitle': 'Monthly fleet analytics',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double subtitleFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) - 2;

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
          // Header
          Text(
            "Recent Activity",
            style: GoogleFonts.inter(
              fontSize: titleFontSize + 2,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 16),

          // Activity list
          ...activities.asMap().entries.map((entry) {
            final int index = entry.key + 1;
            final Map<String, String> activity = entry.value;

            return Padding(
              padding: EdgeInsets.only(bottom: padding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        "$index",
                        style: GoogleFonts.inter(
                          color: colorScheme.onPrimary,
                          fontSize: subtitleFontSize - 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Activity details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['title']!,
                          style: GoogleFonts.inter(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface.withOpacity(0.87),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${activity['time']} · ${activity['subtitle']}",
                          style: GoogleFonts.inter(
                            fontSize: subtitleFontSize,
                            color: colorScheme.onSurface.withOpacity(0.6),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}