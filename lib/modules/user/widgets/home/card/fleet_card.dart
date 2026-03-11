import 'package:fleet_stack/core/models/user_fleet_status_summary.dart';
import 'package:fleet_stack/core/models/user_usage_last_7_days.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(screenWidth);

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
  final String mode;
  final void Function(String) onModeChanged;
  final bool loading;
  final UserFleetStatusSummary? fleetStatus;
  final UserUsageLast7Days? usage;
  final int? alertCount;

  const OverviewBox({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.loading,
    required this.fleetStatus,
    required this.usage,
    required this.alertCount,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;
    final titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth);
    final capsuleFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final title = mode == 'Fleet' ? 'Fleet Overview' : 'Usage Overview';

    return CustomBox(
      radius: 25.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  PopupMenuButton<String>(
                    tooltip: 'Switch View',
                    icon: Icon(
                      Icons.arrow_drop_down_circle_outlined,
                      color: colorScheme.primary.withOpacity(0.7),
                      size: 20,
                    ),
                    offset: const Offset(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                        value: 'Usage',
                        label: 'Usage Overview',
                        icon: Icons.insights_rounded,
                        isSelected: mode == 'Usage',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: spacing + 12),
          _buildCapsuleRow(context, capsuleFontSize, spacing),
        ],
      ),
    );
  }

  Widget _buildCapsuleRow(
    BuildContext context,
    double fontSize,
    double spacing,
  ) {
    final labelSize = fontSize - 2;
    final valueSize = fontSize + 4;
    final items = mode == 'Fleet'
        ? [
            _MetricItem(
              icon: Icons.directions_car,
              label: 'Vehicles',
              value: _intText(fleetStatus?.totalVehicles),
            ),
            _MetricItem(
              icon: Icons.memory_rounded,
              label: 'With Device',
              value: _intText(fleetStatus?.withDevice),
            ),
            _MetricItem(
              icon: Icons.portable_wifi_off_rounded,
              label: 'No Device',
              value: _intText(fleetStatus?.noDevice),
            ),
          ]
        : [
            _MetricItem(
              icon: Icons.route_rounded,
              label: 'Distance',
              value: _kmText(usage?.totalDrivenKm),
            ),
            _MetricItem(
              icon: Icons.timer_outlined,
              label: 'Engine Hrs',
              value: _hoursText(usage?.totalEngineHours),
            ),
            _MetricItem(
              icon: Icons.notifications_active_outlined,
              label: 'Alerts',
              value: _intText(alertCount),
            ),
          ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              right: index == items.length - 1 ? 0 : spacing + 4,
            ),
            child: _capsule(
              context,
              item.icon,
              item.label,
              item.value,
              labelSize,
              valueSize,
              spacing,
            ),
          );
        }).toList(),
      ),
    );
  }

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
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          if (isSelected)
            Icon(
              Icons.check_circle,
              size: 16,
              color: theme.colorScheme.primary,
            ),
        ],
      ),
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
    double width = 110,
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
          SizedBox(height: spacing - 2),
          if (loading)
            AppShimmer(
              width: width * 0.55,
              height: valueFontSize + 2,
              radius: 10,
            )
          else
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

  String _intText(int? value) {
    if (value == null) return '—';
    return value.toString();
  }

  String _kmText(double? value) {
    if (value == null) return '—';
    return _formatNumber(value);
  }

  String _hoursText(double? value) {
    if (value == null) return '—';
    return _formatNumber(value);
  }

  String _formatNumber(double value) {
    final rounded = value.roundToDouble();
    if (rounded == value) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

class _MetricItem {
  final IconData icon;
  final String label;
  final String value;

  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}
