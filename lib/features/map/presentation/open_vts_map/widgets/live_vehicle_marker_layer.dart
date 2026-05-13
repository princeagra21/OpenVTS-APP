part of '../open_vts_map_screen.dart';

class LiveVehicleMarkerLayer extends StatefulWidget {
  const LiveVehicleMarkerLayer({
    required this.points,
    required this.allPoints,
    required this.showVehicleLabels,
    required this.enableRippleEffect,
    required this.selectedVehicleId,
    required this.correctedHeading,
    required this.markerColor,
    required this.markerAssetPath,
    required this.markerBaseAssetPath,
    required this.shouldAnimateRipple,
    required this.onTap,
    required this.onPointsChanged,
  });

  /// UI-ready marker points produced by the map telemetry provider.
  ///
  /// This layer must never parse raw socket payloads or call repositories. It
  /// only animates already-normalized map marker projection data.
  final List<MapVehiclePoint> points;
  final List<MapVehiclePoint> allPoints;
  final bool showVehicleLabels;
  final bool enableRippleEffect;
  final String? selectedVehicleId;
  final double Function(double rawBearing) correctedHeading;
  final Color Function(MapVehiclePoint point, {required bool isSelected}) markerColor;
  final String Function(MapVehiclePoint point, MapVehicleStatusFilter status) markerAssetPath;
  final String Function(MapVehiclePoint point) markerBaseAssetPath;
  final bool Function(MapVehicleStatusFilter status, bool isSelected) shouldAnimateRipple;
  final ValueChanged<MapVehiclePoint> onTap;
  final ValueChanged<List<MapVehiclePoint>> onPointsChanged;

  @override
  State<LiveVehicleMarkerLayer> createState() => _LiveVehicleMarkerLayerState();
}

class _LiveVehicleMarkerLayerState extends State<LiveVehicleMarkerLayer>
    with TickerProviderStateMixin {
  final Map<String, _AnimatedVehicleMarker> _animatedMarkers = {};

  @override
  void initState() {
    super.initState();
    _syncMarkers(widget.points);
  }

  @override
  void didUpdateWidget(covariant LiveVehicleMarkerLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.points, widget.points) ||
        !identical(oldWidget.allPoints, widget.allPoints)) {
      _syncMarkers(widget.points);
    }
  }

  @override
  void dispose() {
    for (final marker in _animatedMarkers.values) {
      marker.stopAndDisposeController();
    }
    _animatedMarkers.clear();
    super.dispose();
  }

  void _syncMarkers(List<MapVehiclePoint> points) {
    widget.onPointsChanged(widget.allPoints);

    final nextIds = points
        .map((e) => e.vehicleId.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    final existingIds = _animatedMarkers.keys.toSet();

    for (final id in existingIds.difference(nextIds)) {
      _disposeVehicleMarker(id);
    }

    for (final point in points) {
      final id = point.vehicleId.trim();
      if (id.isEmpty) continue;

      final nextPosition = LatLng(point.lat, point.lng);
      final marker = _animatedMarkers[id];

      if (marker == null) {
        _animatedMarkers[id] = _AnimatedVehicleMarker(
          position: nextPosition,
          bearing: widget.correctedHeading(point.heading ?? 0),
        );
        continue;
      }

      final currentPosition = marker.currentPosition;
      final rawBearing = _calculateBearing(currentPosition, nextPosition);
      final correctedBearing = widget.correctedHeading(rawBearing);
      final needsMove =
          currentPosition.latitude != nextPosition.latitude ||
          currentPosition.longitude != nextPosition.longitude;

      if (!needsMove) {
        marker.bearing = correctedBearing;
        continue;
      }

      final token = marker.bumpToken();
      marker.stopAndDisposeController();
      marker.bearing = correctedBearing;

      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      );
      final animation = LatLngTween(
        begin: currentPosition,
        end: nextPosition,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
      marker.controller = controller;
      marker.animation = animation;

      controller.addListener(() {
        if (!mounted || _animatedMarkers[id]?.token != token) return;
        updateLocalUiState(this, () {
          marker.position = animation.value;
        });
      });

      controller.addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        if (!mounted || _animatedMarkers[id]?.token != token) return;
        updateLocalUiState(this, () {
          marker.position = nextPosition;
          marker.bearing = correctedBearing;
          marker.stopAndDisposeController();
        });
      });

      controller.forward();
    }
  }

  void _disposeVehicleMarker(String id) {
    final marker = _animatedMarkers.remove(id);
    marker?.stopAndDisposeController();
  }

  double _calculateBearing(LatLng from, LatLng to) {
    const distance = Distance();
    return distance.bearing(from, to);
  }

  @override
  Widget build(BuildContext context) {
    final markers = widget.points
        .map((point) {
          final id = point.vehicleId.trim();
          if (id.isEmpty) return null;

          final marker = _animatedMarkers[id] ??
              (_animatedMarkers[id] = _AnimatedVehicleMarker(
                position: LatLng(point.lat, point.lng),
                bearing: widget.correctedHeading(point.heading ?? 0),
              ));
          final status = normalizeMapVehicleStatus(point);
          final isSelected = id == widget.selectedVehicleId;

          if (!marker.position.latitude.isFinite ||
              !marker.position.longitude.isFinite) {
            marker.position = LatLng(point.lat, point.lng);
          }

          return Marker(
            point: marker.position,
            width: widget.showVehicleLabels ? 168 : 84,
            height: 84,
            child: VehicleMapMarker(
              key: ValueKey(id),
              vehicleName: point.plateNumber,
              bearing: marker.bearing ?? 0,
              markerColor: widget.markerColor(point, isSelected: isSelected),
              markerAssetPath: widget.markerAssetPath(point, status),
              markerBaseAssetPath: widget.markerBaseAssetPath(point),
              showLabel: widget.showVehicleLabels,
              showRipple: widget.enableRippleEffect &&
                  widget.shouldAnimateRipple(status, isSelected),
              isSelected: isSelected,
              status: status,
              onTap: () => widget.onTap(point),
            ),
          );
        })
        .whereType<Marker>()
        .toList(growable: false);

    return RepaintBoundary(child: MarkerLayer(markers: markers));
  }
}
