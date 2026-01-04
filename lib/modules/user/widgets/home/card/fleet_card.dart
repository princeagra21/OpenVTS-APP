// lib/modules/user/widgets/home/card/overview_box.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';

/// A reusable styled container with the app's shadow and border radius design.
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

class OverviewBox extends StatelessWidget {
  final String mode; // 'Fleet' or 'Revenue'
  final Function(String) onModeChanged;

  const OverviewBox({
    super.key,
    required this.mode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;

    // Adaptive sizing logic
    final double titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth);
    final double capsuleFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);

    final String title = mode == 'Fleet' ? 'Fleet Overview' : 'Revenue Ops';

    return CustomBox(
      radius: 25.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title + Professional Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // The Professional Dropdown
                  PopupMenuButton<String>(
                    tooltip: 'Switch View',
                    icon: Icon(
                      Icons.arrow_drop_down_circle_outlined, 
                      color: colorScheme.primary.withOpacity(0.7),
                      size: 20,
                    ),
                    // offset: Positioning the menu exactly below the trigger icon
                    offset: const Offset(0, 40), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    onSelected: onModeChanged,
                    itemBuilder: (context) => [
                      _buildPopupHeader(context, 'Dashboard Mode'),
                      _buildMenuItem(
                        context,
                        value: 'Fleet',
                        label: 'Fleet Overview',
                        icon: Icons.directions_car_filled_rounded,
                        isSelected: mode == 'Fleet',
                      ),
                      _buildMenuItem(
                        context,
                        value: 'Revenue',
                        label: 'Revenue Ops',
                        icon: Icons.monetization_on_rounded,
                        isSelected: mode == 'Revenue',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: spacing + 12),

          // Horizontal Metrics Capsules
          _buildCapsuleRow(context, capsuleFontSize, spacing),
        ],
      ),
    );
  }

  /// Builds the horizontal scrolling list of metrics based on the current mode
  Widget _buildCapsuleRow(BuildContext context, double fontSize, double spacing) {
    // Shared constants for capsules
    final double labelSize = fontSize - 2;
    final double valueSize = fontSize + 4;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: mode == 'Fleet'
            ? [
                _capsule(context, Icons.directions_car, "Vehicles", "1,284", labelSize, valueSize, spacing),
                SizedBox(width: spacing + 4),
                _capsule(context, Icons.people_alt_rounded, "Active", "641", labelSize, valueSize, spacing),
                SizedBox(width: spacing + 4),
                _capsule(context, Icons.online_prediction, "Online", "1,012", labelSize, valueSize, spacing),
              ]
            : [
                _capsule(context, Icons.attach_money, "ARR", "\$1.92M", labelSize, valueSize, spacing),
                SizedBox(width: spacing + 4),
                _capsule(context, Icons.calendar_today, "MRR", "\$160k", labelSize, valueSize, spacing),
                SizedBox(width: spacing + 4),
                _capsule(context, Icons.trending_down, "Churn", "1.2%", labelSize, valueSize, spacing),
              ],
      ),
    );
  }

  /// Professional Popup Header (Non-clickable label)
  PopupMenuEntry<String> _buildPopupHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return PopupMenuItem<String>(
      enabled: false,
      height: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.outline,
              letterSpacing: 1.1,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  /// Professional Popup Menu Item with selection state
  PopupMenuItem<String> _buildMenuItem(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon, 
            size: 20, 
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          if (isSelected)
            Icon(Icons.check_circle, size: 16, color: theme.colorScheme.primary),
        ],
      ),
    );
  }

  /// Individual metric capsule UI
  Widget _capsule(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    double labelFontSize,
    double valueFontSize,
    double spacing, {
    double width = 100,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(vertical: spacing, horizontal: 8),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: labelFontSize + 2, color: cs.primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}