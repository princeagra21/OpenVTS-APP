import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum GeofenceType { circle, polygon, rectangle, line, poi, route }

class Geofence {
  final GeofenceType type;
  final String label;
  final Color color;
  final double? radius;
  final List<LatLng> points;
  final double? width;

  Geofence({
    required this.type,
    required this.label,
    this.color = Colors.blue,
    this.radius,
    this.points = const [],
    this.width,
  });
}
