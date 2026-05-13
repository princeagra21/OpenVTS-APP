import 'package:latlong2/latlong.dart';

import 'create_user_landmark_input.dart';

class UpdateUserLandmarkInput {
  const UpdateUserLandmarkInput({
    required this.id,
    required this.name,
    required this.shape,
    required this.points,
    this.colorHex = '#2196F3',
    this.radiusMeters,
    this.widthMeters,
    this.isActive = true,
  });

  final String id;
  final String name;
  final UserLandmarkShape shape;
  final List<LatLng> points;
  final String colorHex;
  final double? radiusMeters;
  final double? widthMeters;
  final bool isActive;

  bool get canPersist => id.trim().isNotEmpty &&
      CreateUserLandmarkInput(
        name: name,
        shape: shape,
        points: points,
        colorHex: colorHex,
        radiusMeters: radiusMeters,
        widthMeters: widthMeters,
        isActive: isActive,
      ).canPersist;
}
