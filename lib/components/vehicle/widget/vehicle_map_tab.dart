// components/vehicle/widget/vehicle_map_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class VehicleMapTab extends StatelessWidget {
  final LatLng vehicleLocation;
  final String vehiclePlate;

  const VehicleMapTab({
    super.key,
    required this.vehicleLocation,
    this.vehiclePlate = "Vehicle",
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // LayoutBuilder + ConstrainedBox ensures bounded height no matter where it's placed
    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: constraints.maxHeight.isInfinite 
                ? MediaQuery.of(context).size.height 
                : constraints.maxHeight,
          ),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: vehicleLocation,
              initialZoom: 15.0,
              minZoom: 3,
              maxZoom: 18,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.fleetstack.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: vehicleLocation,
                    width: 140,
                    height: 140,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withOpacity(0.98),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colorScheme.primary, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            vehiclePlate,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          Icons.location_on,
                          size: 52,
                          color: colorScheme.primary,
                          shadows: const [
                            Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}