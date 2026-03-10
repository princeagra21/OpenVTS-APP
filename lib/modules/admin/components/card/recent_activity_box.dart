import 'package:fleet_stack/core/models/admin_vehicle_preview_item.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/adaptive_utils.dart';

class SmallTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedBackground;

  const SmallTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedBackground,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double hPadding = AdaptiveUtils.getHorizontalPadding(screenWidth) - 4;
    final double vPadding =
        AdaptiveUtils.getLeftSectionSpacing(screenWidth) - 2;
    final double fontSize = AdaptiveUtils.getTitleFontSize(screenWidth);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
        decoration: BoxDecoration(
          color: selected
              ? (selectedBackground ?? colorScheme.primary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.onSurface, width: 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class RecentActivityBox extends StatefulWidget {
  /// Endpoints used for vehicles preview (FleetStack-API-Reference.md):
  /// - GET /admin/vehicles (limit=5)
  ///   keys: vehicles[].id, plateNumber/name, status/motion, updatedAt/lastSeen
  /// - GET /admin/map-telemetry
  ///   keys: data[].vehicleId|imei + status/motion for live-status enrichment
  final List<AdminVehiclePreviewItem>? vehicles;
  final bool loading;

  const RecentActivityBox({
    super.key,
    required this.vehicles,
    required this.loading,
  });

  @override
  State<RecentActivityBox> createState() => _RecentActivityBoxState();
}

class _RecentActivityBoxState extends State<RecentActivityBox> {
  String activityTab = 'Vehicles';

  Map<String, Color> getStatusColors(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return {
      'Active': colorScheme.primary,
      'Idle': colorScheme.primary.withOpacity(0.7),
      'Running': Colors.green,
      'Stop': Colors.orange,
      'Inactive': colorScheme.error,
      '—': colorScheme.onSurface.withOpacity(0.35),
    };
  }

  Widget _buildLoadingRow(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double itemPadding = AdaptiveUtils.getLeftSectionSpacing(screenWidth);
    final avatarRadius = AdaptiveUtils.getAvatarSize(screenWidth) / 2.4;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: itemPadding),
      child: Row(
        children: [
          AppShimmer(
            width: avatarRadius * 2,
            height: avatarRadius * 2,
            radius: avatarRadius,
          ),
          SizedBox(width: itemPadding + 2),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer(width: 140, height: 14, radius: 7),
                SizedBox(height: 8),
                AppShimmer(width: 110, height: 12, radius: 6),
              ],
            ),
          ),
          SizedBox(width: itemPadding + 2),
          const AppShimmer(width: 72, height: 28, radius: 14),
        ],
      ),
    );
  }

  Widget _buildVehicleRow(
    BuildContext context,
    AdminVehiclePreviewItem item, {
    bool placeholder = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double mainFontSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double subFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final double badgeFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final double itemPadding = AdaptiveUtils.getLeftSectionSpacing(screenWidth);
    final statusColors = getStatusColors(context);

    final status = placeholder ? '—' : item.statusLabel;
    final label = placeholder ? '—' : item.plateNumber;
    final time = placeholder ? '—' : item.lastSeenLabel;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: itemPadding),
      child: Row(
        children: [
          CircleAvatar(
            radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.4,
            backgroundColor: colorScheme.surfaceVariant,
            child: Icon(Icons.directions_car, color: colorScheme.primary),
          ),
          SizedBox(width: itemPadding + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: mainFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: subFontSize,
                    color: colorScheme.onSurface.withOpacity(0.54),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: itemPadding + 2),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: itemPadding + 2,
              vertical: itemPadding - 2,
            ),
            decoration: BoxDecoration(
              color: statusColors[status] ?? statusColors['—'],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: GoogleFonts.inter(
                color: colorScheme.onPrimary,
                fontSize: badgeFontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double linkFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) + 1;

    final vehicles = widget.vehicles ?? const <AdminVehiclePreviewItem>[];
    final showPlaceholders = !widget.loading && vehicles.isEmpty;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: AdaptiveUtils.getIconPaddingLeft(screenWidth) - 4,
                runSpacing: 8,
                children: ['Vehicles'].map((tab) {
                  return SmallTab(
                    label: tab,
                    selected: activityTab == tab,
                    onTap: () => setState(() => activityTab = tab),
                  );
                }).toList(),
              ),
              InkWell(
                onTap: () {
                  context.push(
                    '/admin/all-activities',
                    extra: {'type': activityTab},
                  );
                },
                child: Text(
                  'View all',
                  style: GoogleFonts.inter(
                    fontSize: linkFontSize,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: padding),
          SizedBox(
            height: 320,
            child: ListView.separated(
              itemCount: widget.loading
                  ? 5
                  : (showPlaceholders ? 5 : vehicles.length),
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: colorScheme.onSurface.withOpacity(0.08),
              ),
              itemBuilder: (_, i) {
                if (widget.loading) return _buildLoadingRow(context);
                if (showPlaceholders) {
                  return _buildVehicleRow(
                    context,
                    const AdminVehiclePreviewItem(<String, dynamic>{}),
                    placeholder: true,
                  );
                }
                return _buildVehicleRow(context, vehicles[i]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
