import 'package:latlong2/latlong.dart';

enum UserLandmarkShape { circle, polygon, rectangle, line, poi, route }

class CreateUserLandmarkInput {
  const CreateUserLandmarkInput({
    required this.name,
    required this.shape,
    required this.points,
    this.colorHex = '#2196F3',
    this.radiusMeters,
    this.widthMeters,
    this.isActive = true,
  });

  final String name;
  final UserLandmarkShape shape;
  final List<LatLng> points;
  final String colorHex;
  final double? radiusMeters;
  final double? widthMeters;
  final bool isActive;

  bool get canPersist {
    switch (shape) {
      case UserLandmarkShape.circle:
      case UserLandmarkShape.poi:
        return name.trim().isNotEmpty && points.isNotEmpty;
      case UserLandmarkShape.line:
      case UserLandmarkShape.route:
        return name.trim().isNotEmpty && points.length >= 2;
      case UserLandmarkShape.polygon:
      case UserLandmarkShape.rectangle:
        return name.trim().isNotEmpty && points.length >= 3;
    }
  }
}
