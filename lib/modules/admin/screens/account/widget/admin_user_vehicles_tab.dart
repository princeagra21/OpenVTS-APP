import 'package:fleet_stack/core/models/admin_vehicle_list_item.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/screens/account/widget/admin_user_details_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUserVehiclesTab extends StatelessWidget {
  final List<AdminVehicleListItem> items;
  final bool loading;
  final double bodyFontSize;
  final double smallFontSize;

  const AdminUserVehiclesTab({
    super.key,
    required this.items,
    required this.loading,
    required this.bodyFontSize,
    required this.smallFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showNoData = !loading && items.isEmpty;

    return Column(
      children: [
        _buildOverviewCard(context, colorScheme),
        const SizedBox(height: 24),
        if (showNoData)
          emptyStateCard(
            context,
            title: 'No vehicles found',
            subtitle:
                'Try adjusting search or ask superadmin to assign vehicles.',
          ),
        if (loading)
          ...List<Widget>.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: listShimmer(context, count: 1, height: 188),
            ),
          ),
        if (!showNoData && !loading)
          Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: items
                  .map(
                    (vehicle) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildVehicleCard(context, vehicle),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildOverviewCard(BuildContext context, ColorScheme colorScheme) {
    final total = items.length;
    final active = items.where((v) => v.isActive == true).length;
    final inactive = items.where((v) => v.isActive != true).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
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
              Text(
                'Total Vehicles',
                style: GoogleFonts.inter(
                  fontSize: bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  letterSpacing: 0.8,
                ),
              ),
              loading
                  ? AppShimmer(
                      width: (bodyFontSize * 2) * 0.9,
                      height: (bodyFontSize * 2) * 0.8,
                      radius: 8,
                    )
                  : Text(
                      '$total',
                      style: GoogleFonts.inter(
                        fontSize: bodyFontSize * 2,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'currently tracked',
            style: GoogleFonts.inter(
              fontSize: smallFontSize,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: colorScheme.onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: 20),
          if (loading) ...[
            _statusSkeleton(),
            const SizedBox(height: 16),
            _statusSkeleton(),
          ] else ...[
            _statusRow(context, 'Active', '$active', colorScheme.primary),
            const SizedBox(height: 16),
            _statusRow(context, 'Inactive', '$inactive', colorScheme.error),
          ],
        ],
      ),
    );
  }

  Widget _statusRow(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: bodyFontSize,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: bodyFontSize + 2,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusSkeleton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppShimmer(width: 90, height: 18, radius: 8),
        AppShimmer(width: 64, height: 20, radius: 8),
      ],
    );
  }

  Widget _buildVehicleCard(BuildContext context, AdminVehicleListItem vehicle) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = safeText(
      vehicle.plateNumber.isNotEmpty ? vehicle.plateNumber : vehicle.nameModel,
    );
    final subtitle = safeText(vehicle.nameModel);
    final imei = safeText(vehicle.imei);
    final vin = safeText(vehicle.vin);
    final sim = safeText(vehicle.raw['simNumber']?.toString());
    final model = safeText(vehicle.raw['model']?.toString());
    final lastSeen = formatDateLabel(vehicle.lastActivityAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
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
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: bodyFontSize + 1,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              statusChip(context, vehicle.statusLabel, smallFontSize),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: smallFontSize + 1,
              color: colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 12),
          detailLine(context, 'IMEI', imei, bodyFontSize),
          const SizedBox(height: 8),
          detailLine(context, 'VIN', vin, bodyFontSize),
          const SizedBox(height: 8),
          detailLine(context, 'SIM', sim, bodyFontSize),
          const SizedBox(height: 8),
          detailLine(context, 'Model', model, bodyFontSize),
          const SizedBox(height: 8),
          detailLine(context, 'Last Seen', lastSeen, bodyFontSize),
        ],
      ),
    );
  }
}
