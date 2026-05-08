import 'package:flutter/material.dart';

class MapSettingsSheet extends StatelessWidget {
  final bool showVehicleLabels;
  final bool enableCluster;
  final bool enableRippleEffect;
  final bool showGeofence;
  final bool showPoi;
  final bool showRoutes;
  final ValueChanged<bool> onVehicleLabelsChanged;
  final ValueChanged<bool> onClusterChanged;
  final ValueChanged<bool> onRippleEffectChanged;
  final ValueChanged<bool> onGeofenceChanged;
  final ValueChanged<bool> onPoiChanged;
  final ValueChanged<bool> onRoutesChanged;

  const MapSettingsSheet({
    super.key,
    required this.showVehicleLabels,
    required this.enableCluster,
    required this.enableRippleEffect,
    required this.showGeofence,
    required this.showPoi,
    required this.showRoutes,
    required this.onVehicleLabelsChanged,
    required this.onClusterChanged,
    required this.onRippleEffectChanged,
    required this.onGeofenceChanged,
    required this.onPoiChanged,
    required this.onRoutesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.8,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Map Settings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: cs.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _settingRow(
              context,
              icon: Icons.label_outline,
              title: 'Vehicle Label',
              description: 'Show vehicle name next to the icon on the map',
              value: showVehicleLabels,
              onChanged: onVehicleLabelsChanged,
            ),
            _settingRow(
              context,
              icon: Icons.filter_center_focus_outlined,
              title: 'Cluster',
              description: 'Group nearby vehicles into clusters at lower zoom',
              value: enableCluster,
              onChanged: onClusterChanged,
            ),
            _settingRow(
              context,
              icon: Icons.waves_outlined,
              title: 'Ripple Effect',
              description: 'Show animated pulse around running or selected vehicles',
              value: enableRippleEffect,
              onChanged: onRippleEffectChanged,
            ),
            _settingRow(
              context,
              icon: Icons.fence_outlined,
              title: 'Geofence',
              description: 'Display geofence boundaries on the map',
              value: showGeofence,
              onChanged: onGeofenceChanged,
            ),
            _settingRow(
              context,
              icon: Icons.place_outlined,
              title: 'POI',
              description: 'Show points of interest markers',
              value: showPoi,
              onChanged: onPoiChanged,
            ),
            _settingRow(
              context,
              icon: Icons.route_outlined,
              title: 'Route',
              description: 'Display saved routes on the map',
              value: showRoutes,
              onChanged: onRoutesChanged,
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _settingRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeThumbColor: cs.primary,
              activeTrackColor: cs.primary.withValues(alpha: 0.28),
              inactiveThumbColor: cs.primary,
              inactiveTrackColor: cs.primary.withValues(alpha: 0.14),
            ),
          ],
        ),
      ),
    );
  }
}
