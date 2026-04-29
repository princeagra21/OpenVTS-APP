import 'package:fleet_stack/core/models/map_vehicle_point.dart';
import 'package:fleet_stack/modules/user/screens/map/models/map_vehicle_status_filter.dart';
import 'package:flutter/material.dart';

class StatusVehicleBottomSheet extends StatelessWidget {
  final MapVehicleStatusFilter filter;
  final List<MapVehiclePoint> vehicles;
  final int count;
  final Color statusColor;
  final String title;
  final ValueChanged<MapVehiclePoint> onVehicleTap;
  final String Function(MapVehiclePoint vehicle) titleBuilder;
  final String Function(MapVehiclePoint vehicle) lastSeenBuilder;
  final String Function(MapVehiclePoint vehicle) speedBuilder;
  final String? Function(MapVehiclePoint vehicle) distanceBuilder;
  final String Function(MapVehiclePoint vehicle) addressBuilder;

  const StatusVehicleBottomSheet({
    super.key,
    required this.filter,
    required this.vehicles,
    required this.count,
    required this.statusColor,
    required this.title,
    required this.onVehicleTap,
    required this.titleBuilder,
    required this.lastSeenBuilder,
    required this.speedBuilder,
    required this.distanceBuilder,
    required this.addressBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? cs.surface : Colors.white;
    final divider = cs.outline.withValues(alpha: isDark ? 0.16 : 0.10);

    return DraggableScrollableSheet(
      initialChildSize: 0.64,
      minChildSize: 0.38,
      maxChildSize: 0.72,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.12),
                blurRadius: 22,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$title Vehicles',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$count vehicle${count == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: cs.onSurface),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: divider),
                Expanded(
                  child: vehicles.isEmpty
                      ? _EmptyState(filter: filter)
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          itemCount: vehicles.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final vehicle = vehicles[index];
                            final normalized = normalizeMapVehicleStatus(vehicle);
                            final rowColor = _statusColor(normalized);
                            final hasLocation = vehicle.hasValidPoint &&
                                vehicle.lat.isFinite &&
                                vehicle.lng.isFinite &&
                                !(vehicle.lat == 0 && vehicle.lng == 0);
                            return _VehicleRow(
                              title: titleBuilder(vehicle),
                              lastSeen: lastSeenBuilder(vehicle),
                              speed: speedBuilder(vehicle),
                              distance: distanceBuilder(vehicle),
                              address: addressBuilder(vehicle),
                              statusColor: rowColor,
                              hasLocation: hasLocation,
                              onTap: () => onVehicleTap(vehicle),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VehicleRow extends StatelessWidget {
  final String title;
  final String lastSeen;
  final String speed;
  final String? distance;
  final String address;
  final Color statusColor;
  final bool hasLocation;
  final VoidCallback onTap;

  const _VehicleRow({
    required this.title,
    required this.lastSeen,
    required this.speed,
    required this.distance,
    required this.address,
    required this.statusColor,
    required this.hasLocation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final safeLastSeen = lastSeen.trim().isEmpty || lastSeen.trim() == '-'
        ? 'Unknown'
        : lastSeen.trim();
    final safeSpeed = speed.trim().isEmpty || speed.trim() == '-'
        ? '0 km/h'
        : speed.trim();
    final meta = 'Last update: $safeLastSeen · $safeSpeed';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? cs.surface : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: cs.outline.withValues(alpha: isDark ? 0.16 : 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        if (!hasLocation)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.location_off_outlined,
                              size: 18,
                              color: cs.onSurface.withValues(alpha: 0.45),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: cs.onSurface.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (address.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                    if (distance != null && distance!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        distance!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.my_location_rounded,
                  size: 18,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final MapVehicleStatusFilter filter;

  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.route_outlined,
                size: 30,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No ${filter.label} vehicles',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Vehicles with this status will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(MapVehicleStatusFilter filter) {
  switch (filter) {
    case MapVehicleStatusFilter.running:
      return Colors.green;
    case MapVehicleStatusFilter.stop:
      return Colors.redAccent;
    case MapVehicleStatusFilter.idle:
      return Colors.orange;
    case MapVehicleStatusFilter.inactive:
      return Colors.grey;
    case MapVehicleStatusFilter.noData:
      return Colors.black87;
    case MapVehicleStatusFilter.all:
      return Colors.black;
  }
}
