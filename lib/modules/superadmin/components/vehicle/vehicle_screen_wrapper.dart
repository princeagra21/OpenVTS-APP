import 'package:flutter/material.dart';
import 'package:open_vts/features/vehicles/vehicle_role_config.dart';
import 'package:open_vts/features/vehicles/vehicles_screen.dart';

/// Superadmin vehicle screen wrapper
class VehicleScreen extends StatelessWidget {
  const VehicleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VehiclesScreen(config: VehicleRoleConfig.superadmin);
  }
}