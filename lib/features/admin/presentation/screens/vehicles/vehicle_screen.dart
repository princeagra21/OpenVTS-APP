import 'package:flutter/material.dart';
import 'package:open_vts/features/vehicles/domain/config/vehicle_role_config.dart';
import 'package:open_vts/features/vehicles/presentation/screens/vehicles_screen.dart';

/// Admin vehicle screen wrapper
class VehicleScreen extends StatelessWidget {
  const VehicleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VehiclesScreen(config: VehicleRoleConfig.admin);
  }
}
