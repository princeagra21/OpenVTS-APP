import 'package:latlong2/latlong.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/entities/user_route_form_state.dart';

class OptimizeUserRouteUseCase {
  const OptimizeUserRouteUseCase();

  Result<UserRouteOptimizationResult, AppError> call(List<LatLng> points) {
    if (points.isEmpty) {
      return const Result.failure(ValidationError('Add at least one waypoint before optimizing.'));
    }

    if (points.length == 1) {
      return Result.success(
        UserRouteOptimizationResult(
          points: List<LatLng>.unmodifiable(points),
          totalDistanceKm: 0,
        ),
      );
    }

    final optimized = _twoOptImprove(_nearestNeighbor(points));
    return Result.success(
      UserRouteOptimizationResult(
        points: List<LatLng>.unmodifiable(optimized),
        totalDistanceKm: _calculateTotalDistance(optimized),
      ),
    );
  }

  List<LatLng> _nearestNeighbor(List<LatLng> points) {
    final distance = const Distance();
    final remaining = points.toList(growable: true);
    final ordered = <LatLng>[];

    var current = remaining.removeAt(0);
    ordered.add(current);

    while (remaining.isNotEmpty) {
      var nearestIndex = 0;
      var nearestDistance = double.infinity;
      for (var i = 0; i < remaining.length; i++) {
        final d = distance(current, remaining[i]);
        if (d < nearestDistance) {
          nearestDistance = d;
          nearestIndex = i;
        }
      }
      current = remaining.removeAt(nearestIndex);
      ordered.add(current);
    }
    return ordered;
  }

  List<LatLng> _twoOptImprove(List<LatLng> route) {
    final out = route.toList(growable: true);
    final distance = const Distance();
    var improved = true;
    while (improved) {
      improved = false;
      for (var i = 1; i < out.length - 2; i++) {
        for (var j = i + 2; j < out.length - 1; j++) {
          final oldDistance = distance.as(LengthUnit.Meter, out[i - 1], out[i]) + distance.as(LengthUnit.Meter, out[j], out[j + 1]);
          final newDistance = distance.as(LengthUnit.Meter, out[i - 1], out[j]) + distance.as(LengthUnit.Meter, out[i], out[j + 1]);
          if (newDistance < oldDistance) {
            final reversed = out.sublist(i, j + 1).reversed.toList();
            out.replaceRange(i, j + 1, reversed);
            improved = true;
          }
        }
      }
    }
    return out;
  }

  double _calculateTotalDistance(List<LatLng> route) {
    final distance = const Distance();
    var total = 0.0;
    for (var i = 0; i < route.length - 1; i++) {
      total += distance.as(LengthUnit.Kilometer, route[i], route[i + 1]);
    }
    return total;
  }
}
