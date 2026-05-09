import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:open_vts/core/utils/app_utils.dart';

import '../models/map_vehicle_status_filter.dart';

class VehicleMapMarker extends StatelessWidget {
  final String vehicleName;
  final double bearing;
  final Color markerColor;
  final String markerAssetPath;
  final String markerBaseAssetPath;
  final bool showLabel;
  final bool showRipple;
  final bool isSelected;
  final VoidCallback onTap;
  final MapVehicleStatusFilter status;

  const VehicleMapMarker({
    super.key,
    required this.vehicleName,
    required this.bearing,
    required this.markerColor,
    required this.markerAssetPath,
    required this.markerBaseAssetPath,
    required this.showLabel,
    required this.showRipple,
    required this.isSelected,
    required this.onTap,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelBg = isDark
        ? Colors.black.withValues(alpha: 0.70)
        : Colors.white.withValues(alpha: 0.88);
    final labelText = isDark ? Colors.white : Colors.black;
    final showRipple = this.showRipple;

    final vehicle = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: (bearing * math.pi) / 180,
              child: Image.asset(
                markerAssetPath,
                // NOTE: Asset has alpha transparency.
                width: isSelected ? 60 : 56,
                height: isSelected ? 60 : 56,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  AppLogger.debug(
                    'Vehicle asset failed: $markerAssetPath => $error',
                  );
                  return Image.asset(
                    markerBaseAssetPath,
                    width: isSelected ? 60 : 56,
                    height: isSelected ? 60 : 56,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, baseError, baseStackTrace) {
                      AppLogger.debug(
                        'Base vehicle asset failed: $markerBaseAssetPath => $baseError',
                      );
                      return Icon(
                        Icons.local_shipping_rounded,
                        size: isSelected ? 32 : 28,
                        color: markerColor,
                      );
                    },
                  );
                },
              ),
            ),
            // Status Dot
            Positioned(
              right: isSelected ? 4 : 8,
              bottom: isSelected ? 4 : 8,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: markerColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Container(
            constraints: const BoxConstraints(maxWidth: 88),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: labelBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Text(
              vehicleName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: labelText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: showLabel ? 168 : 84,
        height: 84,
        child: VehicleRippleMarker(
          showRipple: showRipple,
          isSelected: isSelected,
          rippleColor: markerColor,
          child: vehicle,
        ),
      ),
    );
  }
}

class VehicleRippleMarker extends StatelessWidget {
  final Widget child;
  final bool showRipple;
  final bool isSelected;
  final Color rippleColor;

  const VehicleRippleMarker({
    super.key,
    required this.child,
    required this.showRipple,
    this.isSelected = false,
    this.rippleColor = const Color(0xFF4DA3FF),
  });

  @override
  Widget build(BuildContext context) {
    if (!showRipple) {
      return child;
    }
    return _AnimatedVehicleRipple(
      isSelected: isSelected,
      rippleColor: rippleColor,
      child: child,
    );
  }
}

class _AnimatedVehicleRipple extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final Color rippleColor;

  const _AnimatedVehicleRipple({
    required this.child,
    required this.isSelected,
    required this.rippleColor,
  });

  @override
  State<_AnimatedVehicleRipple> createState() => _AnimatedVehicleRippleState();
}

class _AnimatedVehicleRippleState extends State<_AnimatedVehicleRipple>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1650),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildRipple(double progress, Color color) {
    final size = lerpDouble(26, 58, progress)!;
    final opacity = lerpDouble(0.28, 0.0, progress)!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
        border: Border.all(
          color: color.withValues(alpha: opacity * 0.75),
          width: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rippleColor = widget.rippleColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final p1 = _controller.value;
        final p2 = (_controller.value + 0.5) % 1.0;

        return SizedBox(
          width: 84,
          height: 84,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              _buildRipple(p1, rippleColor),
              _buildRipple(p2, rippleColor),
              // NOTE: Vehicle marker assets must be PNGs with alpha transparency.
              // Any baked-in white/gray background in the asset will show as a rectangle.
              widget.child,
            ],
          ),
        );
      },
    );
  }
}
