// components/admin/admin_info_boxes.dart
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:fleet_stack/core/models/admin_profile.dart';

class AdminInfoBoxes extends StatelessWidget {
  final AdminProfile? profile;
  final bool loading;

  const AdminInfoBoxes({super.key, this.profile, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    // Adaptive values
    final double horizontalPadding = AdaptiveUtils.getHorizontalPadding(
      screenWidth,
    );
    final double titleFontSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double contentFontSize =
        AdaptiveUtils.getTitleFontSize(screenWidth) + 1;

    final p = profile;
    final vehicles = p == null ? '-' : p.vehiclesCount.toString();
    final credits = p == null ? '-' : p.credits.toString();
    final lastLogin = _orDash(p?.lastLogin);
    final created = _orDash(p?.createdAt);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoBox(
                context: context,
                title: "Vehicles",
                content: vehicles,
                loading: loading,
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
                content: credits,
                loading: loading,
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
                content: lastLogin,
                loading: loading,
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
                content: created,
                loading: loading,
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
    required bool loading,
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
            child: loading
                ? const Align(
                    alignment: Alignment.centerLeft,
                    child: AppShimmer(
                      width: double.infinity,
                      height: 20,
                      radius: 8,
                    ),
                  )
                : Text(
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

  String _orDash(String? value) {
    if (value == null) return '-';
    final text = value.trim();
    return text.isEmpty ? '-' : text;
  }
}
