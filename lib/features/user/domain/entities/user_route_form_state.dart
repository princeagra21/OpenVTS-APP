import 'package:latlong2/latlong.dart';
import 'package:open_vts/features/user/domain/entities/user_route_item.dart';

class UserRouteFormState {
  const UserRouteFormState({
    this.selectedRoute,
    this.assignedDriver,
    this.routePoints = const <LatLng>[],
    this.optimizationResult,
  });

  final UserRouteItem? selectedRoute;
  final String? assignedDriver;
  final List<LatLng> routePoints;
  final UserRouteOptimizationResult? optimizationResult;

  UserRouteFormState copyWith({
    Object? selectedRoute = _unchanged,
    Object? assignedDriver = _unchanged,
    List<LatLng>? routePoints,
    Object? optimizationResult = _unchanged,
  }) {
    return UserRouteFormState(
      selectedRoute: identical(selectedRoute, _unchanged) ? this.selectedRoute : selectedRoute as UserRouteItem?,
      assignedDriver: identical(assignedDriver, _unchanged) ? this.assignedDriver : assignedDriver as String?,
      routePoints: routePoints ?? this.routePoints,
      optimizationResult: identical(optimizationResult, _unchanged)
          ? this.optimizationResult
          : optimizationResult as UserRouteOptimizationResult?,
    );
  }
}

class UserRouteOptimizationResult {
  const UserRouteOptimizationResult({
    required this.points,
    required this.totalDistanceKm,
  });

  final List<LatLng> points;
  final double totalDistanceKm;
}

class UserRouteEffect {
  const UserRouteEffect.success(this.message) : isError = false;
  const UserRouteEffect.error(this.message) : isError = true;

  final String message;
  final bool isError;
}

const Object _unchanged = Object();
