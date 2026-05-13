import 'package:latlong2/latlong.dart';

import 'create_user_landmark_input.dart';

class UserLandmarkFormState {
  const UserLandmarkFormState({
    this.drawnPoints = const <LatLng>[],
    this.selectedShape = UserLandmarkShape.circle,
    this.radiusMeters = 25,
  });

  final List<LatLng> drawnPoints;
  final UserLandmarkShape selectedShape;
  final double radiusMeters;

  UserLandmarkFormState copyWith({
    List<LatLng>? drawnPoints,
    UserLandmarkShape? selectedShape,
    double? radiusMeters,
  }) {
    return UserLandmarkFormState(
      drawnPoints: drawnPoints ?? this.drawnPoints,
      selectedShape: selectedShape ?? this.selectedShape,
      radiusMeters: radiusMeters ?? this.radiusMeters,
    );
  }
}
