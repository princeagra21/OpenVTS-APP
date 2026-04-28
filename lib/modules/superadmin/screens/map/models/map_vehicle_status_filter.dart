import 'package:fleet_stack/core/models/map_vehicle_point.dart';
import 'package:flutter/material.dart';

enum MapVehicleStatusFilter {
  all,
  running,
  stop,
  idle,
  inactive,
  noData,
}

extension MapVehicleStatusFilterUi on MapVehicleStatusFilter {
  String get label {
    switch (this) {
      case MapVehicleStatusFilter.all:
        return 'All';
      case MapVehicleStatusFilter.running:
        return 'Running';
      case MapVehicleStatusFilter.stop:
        return 'Stop';
      case MapVehicleStatusFilter.idle:
        return 'Idle';
      case MapVehicleStatusFilter.inactive:
        return 'Inactive';
      case MapVehicleStatusFilter.noData:
        return 'No Data';
    }
  }

  IconData get icon {
    switch (this) {
      case MapVehicleStatusFilter.all:
        return Icons.grid_view_rounded;
      case MapVehicleStatusFilter.running:
        return Icons.local_shipping_outlined;
      case MapVehicleStatusFilter.stop:
        return Icons.location_on_outlined;
      case MapVehicleStatusFilter.idle:
        return Icons.access_time_rounded;
      case MapVehicleStatusFilter.inactive:
        return Icons.link_off_rounded;
      case MapVehicleStatusFilter.noData:
        return Icons.help_outline_rounded;
    }
  }
}

class MapVehicleStatusCounts {
  final int all;
  final int running;
  final int stop;
  final int idle;
  final int inactive;
  final int noData;

  const MapVehicleStatusCounts({
    required this.all,
    required this.running,
    required this.stop,
    required this.idle,
    required this.inactive,
    required this.noData,
  });

  const MapVehicleStatusCounts.empty()
      : all = 0,
        running = 0,
        stop = 0,
        idle = 0,
        inactive = 0,
        noData = 0;

  int countFor(MapVehicleStatusFilter filter) {
    switch (filter) {
      case MapVehicleStatusFilter.all:
        return all;
      case MapVehicleStatusFilter.running:
        return running;
      case MapVehicleStatusFilter.stop:
        return stop;
      case MapVehicleStatusFilter.idle:
        return idle;
      case MapVehicleStatusFilter.inactive:
        return inactive;
      case MapVehicleStatusFilter.noData:
        return noData;
    }
  }
}

MapVehicleStatusCounts buildMapVehicleStatusCounts(List<MapVehiclePoint> points) {
  var running = 0;
  var stop = 0;
  var idle = 0;
  var inactive = 0;
  var noData = 0;

  for (final point in points) {
    switch (normalizeMapVehicleStatus(point)) {
      case MapVehicleStatusFilter.running:
        running += 1;
      case MapVehicleStatusFilter.stop:
        stop += 1;
      case MapVehicleStatusFilter.idle:
        idle += 1;
      case MapVehicleStatusFilter.inactive:
        inactive += 1;
      case MapVehicleStatusFilter.noData:
        noData += 1;
      case MapVehicleStatusFilter.all:
        // no-op
        break;
    }
  }

  return MapVehicleStatusCounts(
    all: points.length,
    running: running,
    stop: stop,
    idle: idle,
    inactive: inactive,
    noData: noData,
  );
}

List<MapVehiclePoint> filterMapVehiclePoints(
  List<MapVehiclePoint> points,
  MapVehicleStatusFilter filter,
) {
  if (filter == MapVehicleStatusFilter.all) return points;
  return points.where((point) {
    final normalized = normalizeMapVehicleStatus(point);
    if (normalized != filter) return false;
    return point.hasValidPoint;
  }).toList();
}

MapVehicleStatusFilter normalizeMapVehicleStatus(MapVehiclePoint point) {
  final status = _normalizeText(point.status);
  final ignition = _normalizeText(point.ignition);
  final speed = point.speed ?? 0;
  final lastSeen = DateTime.tryParse(point.updatedAt);

  if (!point.hasValidPoint) {
    return MapVehicleStatusFilter.noData;
  }

  if (_matchesAny(status, const [
    'running',
    'moving',
    'online_moving',
    'active_running',
  ])) {
    return MapVehicleStatusFilter.running;
  }

  if (_matchesAny(status, const ['stop', 'stopped', 'parked'])) {
    return MapVehicleStatusFilter.stop;
  }

  if (_matchesAny(status, const ['idle', 'engine_idle'])) {
    return MapVehicleStatusFilter.idle;
  }

  if (_matchesAny(status, const ['inactive', 'offline', 'disconnected'])) {
    return MapVehicleStatusFilter.inactive;
  }

  if (_matchesAny(status, const ['no_data', 'nodata', 'unknown', 'missing'])) {
    return MapVehicleStatusFilter.noData;
  }

  if (speed > 0) {
    return MapVehicleStatusFilter.running;
  }

  if (_isTruthy(ignition)) {
    return MapVehicleStatusFilter.idle;
  }

  if (_isFalsy(ignition) && lastSeen != null) {
    final age = DateTime.now().toUtc().difference(lastSeen.toUtc());
    if (age.inMinutes >= 15) {
      return MapVehicleStatusFilter.inactive;
    }
    return MapVehicleStatusFilter.stop;
  }

  if (lastSeen == null) {
    return MapVehicleStatusFilter.noData;
  }

  final age = DateTime.now().toUtc().difference(lastSeen.toUtc());
  if (age.inMinutes >= 15) {
    return MapVehicleStatusFilter.inactive;
  }

  return MapVehicleStatusFilter.stop;
}

String _normalizeText(String value) => value.trim().toLowerCase();

bool _matchesAny(String value, List<String> expected) {
  if (value.isEmpty) return false;
  return expected.any((item) => value == item || value.contains(item));
}

bool _isTruthy(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized == 'true' ||
      normalized == '1' ||
      normalized == 'on' ||
      normalized == 'yes' ||
      normalized == 'active';
}

bool _isFalsy(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized == 'false' ||
      normalized == '0' ||
      normalized == 'off' ||
      normalized == 'no' ||
      normalized == 'inactive' ||
      normalized == 'disabled';
}
