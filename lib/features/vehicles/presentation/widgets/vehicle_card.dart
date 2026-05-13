import 'package:flutter/material.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_models.dart';
import 'package:open_vts/features/vehicles/domain/config/vehicle_role_config.dart';
import 'package:open_vts/features/vehicles/presentation/widgets/vehicle_status_chip.dart';

/// Vehicle card widget
class VehicleCard extends StatelessWidget {
  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.config,
    required this.onTap,
  });

  final VehicleItem vehicle;
  final VehicleRoleConfig config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      vehicle.name.isNotEmpty ? vehicle.name : 'Unnamed Vehicle',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  VehicleStatusChip(vehicle: vehicle),
                ],
              ),
              const SizedBox(height: 8),
              if (vehicle.plateNumber.isNotEmpty)
                Text(
                  'Plate: ${vehicle.plateNumber}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (vehicle.driverName.isNotEmpty)
                Text(
                  'Driver: ${vehicle.driverName}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (vehicle.speed.isNotEmpty)
                Text(
                  'Speed: ${vehicle.speed} km/h',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (vehicle.engine.isNotEmpty)
                Text(
                  'Engine: ${vehicle.engine}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
