part of 'geofence.dart';

extension _GeofenceParserHelpers on _GeofenceScreenState {
  Geofence? _geofenceFromApi(Map<String, dynamic> raw) {
    final name = _text(raw['name'] ?? raw['label']);
    if (name.isEmpty) return null;

    final typeRaw = _text(
      raw['type'] ?? _mapValue(raw['geodata'])['kind'] ?? raw['shapeType'],
    ).toUpperCase();
    final geodata = _mapValue(raw['geodata']);
    final geometry = _mapValue(geodata['geometry']);
    final color = _colorFromHex(_text(raw['color']));

    if (typeRaw == 'CIRCLE') {
      final center = _mapValue(geodata['center']);
      final lat = _number(
        center['lat'] ?? raw['latitude'] ?? raw['lat'] ?? raw['centerLat'],
      );
      final lng = _number(
        center['lon'] ??
            center['lng'] ??
            raw['longitude'] ??
            raw['lng'] ??
            raw['lon'] ??
            raw['centerLon'],
      );
      if (lat == null || lng == null) return null;
      return Geofence(
        type: GeofenceType.circle,
        label: name,
        color: color,
        points: [LatLng(lat, lng)],
        radius: _number(geodata['radiusM'] ?? raw['radius'] ?? raw['radiusM']),
      );
    }

    final points = _latLngList(
      geometry['coordinates'] ?? raw['coordinates'] ?? raw['points'],
      closePolygon: typeRaw == 'POLYGON',
    );
    if (points.isEmpty) return null;

    if (typeRaw == 'LINE' ||
        typeRaw == 'ROUTE' ||
        geometry['type'] == 'LineString') {
      return Geofence(
        type: typeRaw == 'ROUTE' ? GeofenceType.route : GeofenceType.line,
        label: name,
        color: color,
        points: points,
        width: _number(
          geodata['toleranceM'] ??
              geodata['toleranceMeters'] ??
              raw['toleranceMeters'] ??
              raw['width'] ??
              raw['buffer'],
        ),
      );
    }

    return Geofence(
      type: typeRaw == 'RECTANGLE' || points.length == 4
          ? GeofenceType.rectangle
          : GeofenceType.polygon,
      label: name,
      color: color,
      points: points,
    );
  }

  Geofence? _routeFromApi(Map<String, dynamic> raw) {
    final name = _text(raw['name'] ?? raw['label']);
    if (name.isEmpty) return null;

    final geodata = _mapValue(raw['geodata']);
    final geometry = _mapValue(geodata['geometry']);
    final points = _latLngList(
      geometry['coordinates'] ?? raw['coordinates'] ?? raw['points'],
    );
    if (points.length < 2) return null;

    return Geofence(
      type: GeofenceType.route,
      label: name,
      color: _colorFromHex(_text(raw['color'])),
      points: points,
      width: _number(
        geodata['toleranceM'] ??
            raw['toleranceMeters'] ??
            raw['width'] ??
            raw['buffer'],
      ),
    );
  }

  Geofence? _poiFromApi(Map<String, dynamic> raw) {
    final name = _text(raw['name'] ?? raw['label']);
    if (name.isEmpty) return null;

    final coordinates = _mapValue(raw['coordinates']);
    final lat = _number(
      coordinates['lat'] ?? raw['latitude'] ?? raw['lat'] ?? raw['centerLat'],
    );
    final lng = _number(
      coordinates['lon'] ??
          coordinates['lng'] ??
          raw['longitude'] ??
          raw['lng'] ??
          raw['lon'] ??
          raw['centerLon'],
    );
    if (lat == null || lng == null) return null;

    return Geofence(
      type: GeofenceType.poi,
      label: name,
      color: _colorFromHex(_text(raw['color'])),
      points: [LatLng(lat, lng)],
      radius:
          _number(raw['toleranceMeters'] ?? raw['radius'] ?? raw['radiusM']) ??
          25,
    );
  }

  Map<String, dynamic> _mapValue(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }

  String _text(Object? value) => (value ?? '').toString().trim();

  double? _number(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Color _colorFromHex(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return Colors.blue;
    var hex = value.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null ? Colors.blue : Color(parsed);
  }

  String _landmarkMeasureLabel(Geofence g) {
    switch (g.type) {
      case GeofenceType.circle:
      case GeofenceType.poi:
        return 'Radius';
      case GeofenceType.line:
      case GeofenceType.route:
        return 'Tolerance';
      case GeofenceType.polygon:
      case GeofenceType.rectangle:
        return 'Vertices';
    }
  }

  String _landmarkMeasureValue(Geofence g) {
    switch (g.type) {
      case GeofenceType.circle:
      case GeofenceType.poi:
        return '${(g.radius ?? 25).round()} m';
      case GeofenceType.line:
      case GeofenceType.route:
        return '${(g.width ?? 50).round()} m';
      case GeofenceType.polygon:
      case GeofenceType.rectangle:
        return '${g.points.length}';
    }
  }

  String _landmarkTypeLabel(Geofence g) {
    switch (g.type) {
      case GeofenceType.circle:
      case GeofenceType.poi:
        return 'Circle';
      case GeofenceType.polygon:
        return 'Polygon';
      case GeofenceType.rectangle:
        return 'Rectangle';
      case GeofenceType.line:
        return 'Line';
      case GeofenceType.route:
        return 'Route';
    }
  }

  Future<void> _showLandmarkInfo(Geofence g) async {
    await _showLandmarkInfoForHits([g]);
  }

  void _focusLandmarkOnMap(Geofence g) {
    if (g.points.isEmpty) return;
    if (g.type == GeofenceType.circle || g.type == GeofenceType.poi) {
      _mapController.move(g.points.first, _GeofenceScreenState._focusMapZoom);
      return;
    }

    if (g.points.length == 1) {
      _mapController.move(g.points.first, _GeofenceScreenState._focusMapZoom);
      return;
    }

    final bounds = LatLngBounds.fromPoints(g.points);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(56)),
    );
  }

  IconData _landmarkIcon(Geofence g) {
    switch (g.type) {
      case GeofenceType.line:
      case GeofenceType.route:
        return Icons.alt_route_outlined;
      case GeofenceType.polygon:
      case GeofenceType.rectangle:
        return Icons.crop_square_outlined;
      case GeofenceType.circle:
      case GeofenceType.poi:
        return Icons.radio_button_checked_outlined;
    }
  }

  String _landmarkSummary(Geofence g) {
    return '${_landmarkTypeLabel(g)} · ${_landmarkMeasureLabel(g)} ${_landmarkMeasureValue(g)}';
  }

  List<LatLng> _latLngList(Object? value, {bool closePolygon = false}) {
    if (value is! List) return const <LatLng>[];
    final points = <LatLng>[];
    for (final item in value) {
      if (item is List && item.length >= 2) {
        final first = _number(item[0]);
        final second = _number(item[1]);
        if (first == null || second == null) continue;

        late final double lat;
        late final double lng;
        if (first.abs() > 60 && second.abs() <= 60) {
          lng = first;
          lat = second;
        } else if (second.abs() > 60 && first.abs() <= 60) {
          lat = first;
          lng = second;
        } else {
          lat = first;
          lng = second;
        }
        points.add(LatLng(lat, lng));
      }
    }

    if (closePolygon &&
        points.length >= 3 &&
        (points.first.latitude != points.last.latitude ||
            points.first.longitude != points.last.longitude)) {
      points.add(points.first);
    }
    return points;
  }

  void _zoomIn() {
    final newZoom = (_currentZoom + 1).clamp(3.0, 18.0);
    _mapController.move(_currentCenter, newZoom);
    setState(() => _currentZoom = newZoom);
  }

  void _zoomOut() {
    final newZoom = (_currentZoom - 1).clamp(3.0, 18.0);
    _mapController.move(_currentCenter, newZoom);
    setState(() => _currentZoom = newZoom);
  }

  double _directedHausdorff(List<LatLng> pointsA, List<LatLng> pointsB) {
    final distance = const Distance();
    double maxMinDist = 0.0;
    for (var p in pointsA) {
      double minDist = double.infinity;
      for (var q in pointsB) {
        final d = distance.as(LengthUnit.Meter, p, q);
        if (d < minDist) minDist = d;
      }
      if (minDist > maxMinDist) maxMinDist = minDist;
    }
    return maxMinDist;
  }

  bool _isTooSimilar(Geofence newGeofence, Geofence existing) {
    if (newGeofence.type != existing.type) return false;
    final distance = const Distance();
    switch (newGeofence.type) {
      case GeofenceType.circle:
      case GeofenceType.poi:
        if (newGeofence.points.isEmpty ||
            existing.points.isEmpty ||
            newGeofence.radius == null ||
            existing.radius == null) {
          return false;
        }
        final d = distance.as(
          LengthUnit.Meter,
          newGeofence.points[0],
          existing.points[0],
        );
        final rDiff = (newGeofence.radius! - existing.radius!).abs();
        return d < 100 && rDiff < 50;
      case GeofenceType.polygon:
      case GeofenceType.rectangle:
      case GeofenceType.line:
      case GeofenceType.route:
        if (newGeofence.points.length < 2 || existing.points.length < 2) {
          return false;
        }
        final d1 = _directedHausdorff(newGeofence.points, existing.points);
        final d2 = _directedHausdorff(existing.points, newGeofence.points);
        final hausdorff = math.max(d1, d2);
        final double nw = newGeofence.width ?? 0.0;
        final double ew = existing.width ?? 0.0;
        final wDiff = (nw - ew).abs();
        return hausdorff < 100 && wDiff < 10;
    }
  }

  Map<String, dynamic> _toGeofencePayload(Geofence g) {
    if (g.points.isEmpty) return const <String, dynamic>{};
    if (g.type == GeofenceType.circle || g.type == GeofenceType.poi) {
      final center = g.points.first;
      final radius = (g.radius ?? 25).round();
      return <String, dynamic>{
        'name': g.label,
        'type': g.type == GeofenceType.poi ? 'POI' : 'CIRCLE',
        'color': '#2196F3',
        'isActive': true,
        'geodata': <String, dynamic>{
          'kind': 'CIRCLE',
          'center': <String, dynamic>{
            'lat': center.latitude,
            'lon': center.longitude,
          },
          'radiusM': radius,
        },
      };
    }

    if (g.type == GeofenceType.line || g.type == GeofenceType.route) {
      final tolerance = (g.width ?? 50).round();
      return <String, dynamic>{
        'name': g.label,
        'description': '',
        'type': g.type == GeofenceType.route ? 'ROUTE' : 'LINE',
        'color': '#3b82f6',
        'isActive': true,
        'geodata': <String, dynamic>{
          'kind': g.type == GeofenceType.route ? 'ROUTE' : 'LINE',
          'geometry': <String, dynamic>{
            'type': 'LineString',
            'coordinates': g.points
                .map((p) => <double>[p.longitude, p.latitude])
                .toList(),
          },
          'toleranceM': tolerance,
        },
      };
    }

    final polygonPoints = List<LatLng>.from(g.points);
    if (polygonPoints.length >= 3 &&
        (polygonPoints.first.latitude != polygonPoints.last.latitude ||
            polygonPoints.first.longitude != polygonPoints.last.longitude)) {
      polygonPoints.add(polygonPoints.first);
    }

    return <String, dynamic>{
      'name': g.label,
      'type': 'POLYGON',
      'color': '#2196F3',
      'isActive': true,
      'geodata': <String, dynamic>{
        'kind': 'POLYGON',
        'geometry': <String, dynamic>{
          'type': 'Polygon',
          'coordinates': [
            polygonPoints
                .map((p) => <double>[p.longitude, p.latitude])
                .toList(),
          ],
        },
      },
    };
  }

  Map<String, dynamic> _toPoiPayload(Geofence g) {
    final point = g.points.first;
    final tolerance = (g.radius ?? 25).round();
    return <String, dynamic>{
      'name': g.label,
      'color': '#2196F3',
      'toleranceMeters': tolerance,
      'coordinates': <String, dynamic>{
        'lat': point.latitude,
        'lon': point.longitude,
      },
    };
  }

  Future<void> _persistGeofence(Geofence g) async {
    for (var existing in _geofences) {
      if (_isTooSimilar(g, existing)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Geofence too similar to an existing one'),
          ),
        );
        return;
      }
    }

    if (_saving) return;
    _saveToken?.cancel('Restart geofence save');
    final token = CancelToken();
    _saveToken = token;

    if (!mounted) return;
    setState(() => _saving = true);

    final repo = _repoOrCreate();
    final Result<void> result;
    switch (g.type) {
      case GeofenceType.circle:
      case GeofenceType.polygon:
      case GeofenceType.rectangle:
      case GeofenceType.line:
      case GeofenceType.route:
        result = await repo.createGeofence(
          _toGeofencePayload(g),
          cancelToken: token,
        );
        break;
      case GeofenceType.poi:
        result = await repo.createPoi(_toPoiPayload(g), cancelToken: token);
        break;
    }

    if (!mounted || token.isCancelled) return;

    result.when(
      success: (_) {
        setState(() {
          _geofences.add(g);
          _saving = false;
          _saveErrorShown = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Landmark saved')));
        if (g.type == GeofenceType.circle || g.type == GeofenceType.poi) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showLandmarkInfo(g);
          });
        }
        _loadLandmarks();
      },
      failure: (error) {
        setState(() => _saving = false);
        if (_isCancelled(error) || _saveErrorShown) return;
        _saveErrorShown = true;
        final message = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't save landmark.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  // Clear all geofences
}
