// components/fleet/fleet_overview_box.dart
import 'package:fleet_stack/core/models/admin_dashboard_summary.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/adaptive_utils.dart';

class CustomBox extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double radius;

  const CustomBox({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.radius = 25.0,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);

    return Container(
      width: width ?? double.infinity,
      height: height,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class FleetOverviewBox extends StatelessWidget {
  final AdminDashboardSummary? summary;
  final bool loading;

  const FleetOverviewBox({super.key, this.summary, this.loading = false});

  String _formatInt(int value) {
    final text = value.toString();
    return text.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  String _displayInt(int value) => summary == null ? '—' : _formatInt(value);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;

    final double titleFontSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double bigNumberFontSize = titleFontSize * 2.4;
    final double descriptionFontSize = AdaptiveUtils.getTitleFontSize(
      screenWidth,
    );
    final double capsuleFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth);

    final String totalVehicles = _displayInt(summary?.totalVehicles ?? 0);
    final String users = _displayInt(summary?.totalUsers ?? 0);
    final String expiring30d = _displayInt(summary?.expiring30d ?? 0);
    final String expired = _displayInt(summary?.expired ?? 0);

    return CustomBox(
      radius: 25.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              loading
                  ? AppShimmer(
                      width: screenWidth * 0.34,
                      height: titleFontSize + 6,
                      radius: 8,
                    )
                  : Text(
                      'Your fleet Today',
                      style: GoogleFonts.inter(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
            ],
          ),
          SizedBox(height: spacing + 4),
          loading
              ? AppShimmer(
                  width: bigNumberFontSize * 2,
                  height: bigNumberFontSize * 0.95,
                  radius: 12,
                )
              : Text(
                  totalVehicles,
                  style: GoogleFonts.inter(
                    fontSize: bigNumberFontSize,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    height: 1.1,
                    letterSpacing: -1.5,
                  ),
                ),
          SizedBox(height: spacing),
          loading
              ? AppShimmer(
                  width: screenWidth * 0.56,
                  height: descriptionFontSize + 4,
                  radius: 8,
                )
              : Text(
                  'Total Vehicles across all admins',
                  style: GoogleFonts.inter(
                    fontSize: descriptionFontSize,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
          SizedBox(height: spacing + 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                loading
                    ? _capsuleShimmer(capsuleFontSize, spacing)
                    : _capsule(
                        context,
                        Icons.people_alt_rounded,
                        'Users',
                        users,
                        capsuleFontSize - 2,
                        capsuleFontSize + 4,
                        spacing,
                      ),
                SizedBox(width: spacing + 4),
                loading
                    ? _capsuleShimmer(capsuleFontSize, spacing)
                    : _capsule(
                        context,
                        Icons.schedule_rounded,
                        'Expiry (30d)',
                        expiring30d,
                        capsuleFontSize - 2,
                        capsuleFontSize + 4,
                        spacing,
                      ),
                SizedBox(width: spacing + 4),
                loading
                    ? _capsuleShimmer(capsuleFontSize, spacing)
                    : _capsule(
                        context,
                        Icons.cancel_rounded,
                        'Expired',
                        expired,
                        capsuleFontSize - 2,
                        capsuleFontSize + 4,
                        spacing,
                        iconColor: Colors.redAccent,
                      ),
              ],
            ),
          ),
          SizedBox(height: spacing + 12),
        ],
      ),
    );
  }

  Widget _capsuleShimmer(double capsuleFontSize, double spacing) {
    return AppShimmer(
      width: 100,
      height: capsuleFontSize + spacing * 4.2,
      radius: 16,
    );
  }

  Widget _capsule(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    double labelFontSize,
    double valueFontSize,
    double spacing, {
    double width = 100,
    Color? iconColor,
  }) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: Container(
        padding: EdgeInsets.all(spacing),
        decoration: BoxDecoration(
          color: cs.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: labelFontSize + 2,
                  color: iconColor ?? cs.onSurface,
                ),
                SizedBox(width: spacing / 1.5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing / 2),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
