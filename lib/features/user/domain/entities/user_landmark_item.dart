import 'package:latlong2/latlong.dart';

import 'create_user_landmark_input.dart';

class UserLandmarkItem {
  const UserLandmarkItem({
    required this.id,
    required this.name,
    required this.shape,
    required this.points,
    this.colorHex = '#2196F3',
    this.radiusMeters,
    this.widthMeters,
    this.isActive = true,
    this.updatedAt = '',
  });

  final String id;
  final String name;
  final UserLandmarkShape shape;
  final List<LatLng> points;
  final String colorHex;
  final double? radiusMeters;
  final double? widthMeters;
  final bool isActive;
  final String updatedAt;

  UserLandmarkItem copyWith({
    String? id,
    String? name,
    UserLandmarkShape? shape,
    List<LatLng>? points,
    String? colorHex,
    Object? radiusMeters = _unchanged,
    Object? widthMeters = _unchanged,
    bool? isActive,
    String? updatedAt,
  }) {
    return UserLandmarkItem(
      id: id ?? this.id,
      name: name ?? this.name,
      shape: shape ?? this.shape,
      points: points ?? this.points,
      colorHex: colorHex ?? this.colorHex,
      radiusMeters: identical(radiusMeters, _unchanged) ? this.radiusMeters : radiusMeters as double?,
      widthMeters: identical(widthMeters, _unchanged) ? this.widthMeters : widthMeters as double?,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

const Object _unchanged = Object();
