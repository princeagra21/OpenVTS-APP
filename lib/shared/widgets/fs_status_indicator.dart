import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_colors.dart';
import 'package:open_vts/core/theme/app_spacing.dart';
import 'package:open_vts/core/theme/app_text_styles.dart';

enum VehicleStatus { moving, stopped, idle, noData }

class FSVehicleStatusBadge extends StatelessWidget {
  const FSVehicleStatusBadge({required this.status, super.key});

  final VehicleStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      VehicleStatus.moving => (AppColors.vehicleMoving, 'Moving'),
      VehicleStatus.stopped => (AppColors.vehicleStopped, 'Stopped'),
      VehicleStatus.idle => (AppColors.vehicleIdle, 'Idle'),
      VehicleStatus.noData => (AppColors.vehicleNoData, 'No Data'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}
