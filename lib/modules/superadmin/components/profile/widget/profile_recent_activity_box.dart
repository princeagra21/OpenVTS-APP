import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileActivityEntry {
  final String title;
  final String subtitle;
  final String time;

  const ProfileActivityEntry({
    required this.title,
    required this.subtitle,
    required this.time,
  });
}

class ProfileRecentActivityBox extends StatelessWidget {
  final List<ProfileActivityEntry> activities;
  final bool loading;

  const ProfileRecentActivityBox({
    super.key,
    this.activities = const <ProfileActivityEntry>[],
    this.loading = false,
  });

  String _display(String? value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.trim();
    return text.isEmpty ? fallback : text;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double titleFontSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double subtitleFontSize =
        AdaptiveUtils.getTitleFontSize(screenWidth) - 2;

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
            'Recent Activity',
            style: GoogleFonts.roboto(
              fontSize: titleFontSize + 2,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 16),

          if (loading)
            Column(
              children: List<Widget>.generate(
                4,
                (_) => Padding(
                  padding: EdgeInsets.only(bottom: padding),
                  child: const AppShimmer(
                    width: double.infinity,
                    height: 44,
                    radius: 12,
                  ),
                ),
              ),
            )
          else if (activities.isEmpty)
            Text(
              'No recent activity from API.',
              style: GoogleFonts.roboto(
                fontSize: subtitleFontSize,
                color: colorScheme.onSurface.withOpacity(0.65),
              ),
            )
          else
            ...activities.asMap().entries.map((entry) {
              final int index = entry.key + 1;
              final ProfileActivityEntry activity = entry.value;

              return Padding(
                padding: EdgeInsets.only(bottom: padding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$index',
                          style: GoogleFonts.roboto(
                            color: colorScheme.onPrimary,
                            fontSize: subtitleFontSize - 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _display(activity.title),
                            style: GoogleFonts.roboto(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_display(activity.time)} | ${_display(activity.subtitle)}',
                            style: GoogleFonts.roboto(
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
