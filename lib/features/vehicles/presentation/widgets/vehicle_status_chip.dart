import 'package:flutter/material.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_models.dart';

/// Vehicle status chip widget
class VehicleStatusChip extends StatelessWidget {
  const VehicleStatusChip({
    super.key,
    required this.vehicle,
  });

  final VehicleItem vehicle;

  @override
  Widget build(BuildContext context) {
    final status = _getDisplayStatus();
    final color = _getStatusColor(context);

    return Chip(
      label: Text(
        status,
        style: TextStyle(
          color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _getDisplayStatus() {
    if (vehicle.motion.isNotEmpty) {
      return vehicle.motion;
    }
    if (vehicle.status.isNotEmpty) {
      return vehicle.status;
    }
    return vehicle.isActive ? 'Active' : 'Inactive';
  }

  Color _getStatusColor(BuildContext context) {
    final status = _getDisplayStatus().toLowerCase();

    if (status.contains('running') || status.contains('moving')) {
      return Colors.green;
    }
    if (status.contains('stopped') || status.contains('idle')) {
      return Colors.orange;
    }
    if (status.contains('active')) {
      return Colors.blue;
    }
    if (status.contains('inactive') || status.contains('offline')) {
      return Colors.grey;
    }

    return Theme.of(context).colorScheme.primary;
  }
}
