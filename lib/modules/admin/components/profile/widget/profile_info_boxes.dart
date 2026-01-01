// components/profile/profile_info_boxes.dart
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart' show AdaptiveUtils;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileInfoBoxes extends StatelessWidget {
  const ProfileInfoBoxes({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double horizontalPadding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    // Increased font sizes for clearer readability
    final double titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 1; // Account activity title
    final double labelFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2; // left label (bigger)
    final double valueFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2; // right value (largest)
    final double smallFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) + 0.5; // small subtitle (if any)
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth) * 1.2;

    // Example values — replace with real data when wiring up
    const String lastLoginExact = "20 Nov 2025, 7:30 PM";
    const String createdDate = "10 Sep 2025";
    const String passwordChanged = "2 months ago";

    return Container(
      padding: EdgeInsets.all(horizontalPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
        border: Border.all(color: colorScheme.outline.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            "Account activity",
            style: GoogleFonts.inter(
              fontSize: titleFontSize - 2,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface.withOpacity(0.9),
            ),
          ),

          SizedBox(height: spacing / 1.1),
          Divider(height: 1.5, color: colorScheme.primary.withOpacity(0.5)),
          SizedBox(height: spacing / 1.1),

          // Last Login (single-line format "Last login: 20 Nov ...")
          _infoRow(
            label: "Last login",
            valueTitle: lastLoginExact,
            labelFontSize: labelFontSize,
            valueFontSize: valueFontSize,
            subtitleFontSize: smallFontSize,
            colorScheme: colorScheme,
            singleLine: true,
          ),

          SizedBox(height: spacing / 1.1),

          // Created (single-line)
          _infoRow(
            label: "Created",
            valueTitle: createdDate,
            labelFontSize: labelFontSize,
            valueFontSize: valueFontSize,
            subtitleFontSize: smallFontSize,
            colorScheme: colorScheme,
            singleLine: true,
          ),

          SizedBox(height: spacing / 1.1),

          // Password last change — label non-bold and single-line ("Password last change: 2 months ago")
          _infoRow(
            label: "Password last change",
            valueTitle: passwordChanged,
            labelFontSize: labelFontSize,
            valueFontSize: valueFontSize,
            subtitleFontSize: smallFontSize,
            colorScheme: colorScheme,
            labelFontWeight: FontWeight.w400,
            valueFontWeight: FontWeight.w200,
            singleLine: true,
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required String label,
    required String valueTitle,
    String? valueSubtitle,
    required double labelFontSize,
    required double valueFontSize,
    required double subtitleFontSize,
    required ColorScheme colorScheme,
    // control weight of the value text (default bold)
    FontWeight valueFontWeight = FontWeight.w200,
    // control weight of the label (default bold)
    FontWeight labelFontWeight = FontWeight.w500,
    // force single-line layout (label + ":" + value on same line)
    bool singleLine = false,
  }) {
    if (singleLine) {
      // Renders: "Label: Value" on one line with styles for each part, ellipsized at the end.
      return Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: GoogleFonts.inter(
                      fontSize: labelFontSize,
                      fontWeight: labelFontWeight,
                      color: colorScheme.onSurface.withOpacity(0.85),
                    ),
                  ),
                  TextSpan(
                    text: valueTitle,
                    style: GoogleFonts.inter(
                      fontSize: valueFontSize,
                      fontWeight: valueFontWeight,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    // Default (multi-line capable) layout — label on the left, value stacked on the right
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left label
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: labelFontSize,
              fontWeight: labelFontWeight,
              color: colorScheme.onSurface.withOpacity(0.85),
            ),
          ),
        ),

        // Right value (title + optional subtitle)
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                valueTitle,
                style: GoogleFonts.inter(
                  fontSize: valueFontSize,
                  fontWeight: valueFontWeight,
                  color: colorScheme.onSurface,
                ),
              ),
              if (valueSubtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  valueSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: subtitleFontSize,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
