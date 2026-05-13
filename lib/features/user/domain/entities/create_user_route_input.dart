import 'package:latlong2/latlong.dart';

class CreateUserRouteInput {
  const CreateUserRouteInput({
    required this.name,
    required this.points,
    this.color = '#2196F3',
    this.toleranceMeters = 100,
    this.assignedDriver,
  });

  final String name;
  final String color;
  final int toleranceMeters;
  final List<LatLng> points;
  final String? assignedDriver;

  bool get canPersist => points.length >= 2;
}
