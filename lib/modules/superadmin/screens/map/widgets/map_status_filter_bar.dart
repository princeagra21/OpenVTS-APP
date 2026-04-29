import 'package:fleet_stack/modules/superadmin/screens/map/models/map_vehicle_status_filter.dart';
import 'package:flutter/material.dart';

class MapStatusFilterBar extends StatelessWidget {
  final MapVehicleStatusFilter selectedFilter;
  final MapVehicleStatusCounts counts;
  final ValueChanged<MapVehicleStatusFilter> onChanged;

  const MapStatusFilterBar({
    super.key,
    required this.selectedFilter,
    required this.counts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = <MapVehicleStatusFilter>[
      MapVehicleStatusFilter.all,
      MapVehicleStatusFilter.running,
      MapVehicleStatusFilter.stop,
      MapVehicleStatusFilter.idle,
      MapVehicleStatusFilter.inactive,
      MapVehicleStatusFilter.noData,
    ];

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = items[index];
          final selected = filter == selectedFilter;
          final count = counts.countFor(filter);
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onChanged(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.black
                    : (isDark
                        ? cs.surface.withValues(alpha: 0.82)
                        : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? Colors.black
                      : cs.outline.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: selected ? 0.18 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter.icon,
                    size: 16,
                    color: selected ? Colors.white : cs.onSurface,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filter.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.15)
                          : cs.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
