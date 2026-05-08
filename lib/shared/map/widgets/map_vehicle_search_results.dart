import 'package:fleet_stack/core/models/map_vehicle_point.dart';
import 'package:flutter/material.dart';

class MapVehicleSearchResultsPanel extends StatelessWidget {
  final List<MapVehiclePoint> vehicles;
  final ValueChanged<MapVehiclePoint> onVehicleTap;
  final String Function(MapVehiclePoint) titleBuilder;
  final String Function(MapVehiclePoint) statusTextBuilder;
  final String Function(MapVehiclePoint) identifierBuilder;
  final String Function(MapVehiclePoint) speedBuilder;
  final Color Function(MapVehiclePoint) statusColorBuilder;
  final bool Function(MapVehiclePoint) hasLocationBuilder;

  const MapVehicleSearchResultsPanel({
    super.key,
    required this.vehicles,
    required this.onVehicleTap,
    required this.titleBuilder,
    required this.statusTextBuilder,
    required this.identifierBuilder,
    required this.speedBuilder,
    required this.statusColorBuilder,
    required this.hasLocationBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? cs.surface : Colors.white;
    final border = cs.outline.withValues(alpha: isDark ? 0.18 : 0.12);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: vehicles.isEmpty
              ? _SearchEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(10),
                  itemCount: vehicles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final vehicle = vehicles[index];
                    final statusText = statusTextBuilder(vehicle);
                    final identifier = identifierBuilder(vehicle);
                    final speed = speedBuilder(vehicle);
                    final hasLocation = hasLocationBuilder(vehicle);

                    final metaParts = <String>[
                      if (identifier.trim().isNotEmpty) identifier.trim(),
                      if (speed.trim().isNotEmpty && speed.trim() != '–')
                        speed.trim(),
                    ];

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => onVehicleTap(vehicle),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? cs.surface : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: BoxDecoration(
                                  color: statusColorBuilder(vehicle),
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
                                            titleBuilder(vehicle),
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
                                            padding: const EdgeInsets.only(
                                              left: 8,
                                            ),
                                            child: Icon(
                                              Icons.location_off_outlined,
                                              size: 18,
                                              color: cs.onSurface
                                                  .withValues(alpha: 0.45),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      [statusText, ...metaParts]
                                          .where((e) => e.trim().isNotEmpty)
                                          .join(' • '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.68),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.10),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.my_location_rounded,
                                  size: 17,
                                  color: cs.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 28,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No vehicles found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try name, plate number, or IMEI',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.60),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
