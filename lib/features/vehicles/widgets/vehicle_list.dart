import 'package:flutter/material.dart';
import 'package:open_vts/features/vehicles/vehicle_models.dart';
import 'package:open_vts/features/vehicles/vehicle_role_config.dart';
import 'package:open_vts/features/vehicles/widgets/vehicle_card.dart';

/// Vehicle list widget
class VehicleList extends StatelessWidget {
  const VehicleList({
    super.key,
    required this.vehicles,
    required this.loading,
    required this.config,
    required this.onVehicleTap,
  });

  final List<VehicleItem> vehicles;
  final bool loading;
  final VehicleRoleConfig config;
  final void Function(VehicleItem) onVehicleTap;

  @override
  Widget build(BuildContext context) {
    if (vehicles.isEmpty && !loading) {
      return const Center(
        child: Text('No vehicles found'),
      );
    }

    return ListView.builder(
      itemCount: vehicles.length + (loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= vehicles.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CircularProgressIndicator(),
          );
        }

        final vehicle = vehicles[index];
        return VehicleCard(
          vehicle: vehicle,
          config: config,
          onTap: () => onVehicleTap(vehicle),
        );
      },
    );
  }
}