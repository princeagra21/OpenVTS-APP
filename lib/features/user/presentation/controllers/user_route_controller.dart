import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/user/di/user_route_providers.dart';
import 'package:open_vts/features/user/domain/entities/create_user_route_input.dart';
import 'package:open_vts/features/user/domain/entities/update_user_route_input.dart';
import 'package:open_vts/features/user/domain/entities/user_route_form_state.dart';
import 'package:open_vts/features/user/domain/entities/user_route_item.dart';

class UserRouteState {
  const UserRouteState({
    this.routes = const <UserRouteItem>[],
    this.selectedRoute,
    this.assignedDriver,
    this.routePoints = const <LatLng>[],
    this.optimizationResult,
    this.isLoading = false,
    this.isSaving = false,
    this.isDeleting = false,
    this.isOptimizing = false,
    this.errorMessage,
    this.effect,
  });

  final List<UserRouteItem> routes;
  final UserRouteItem? selectedRoute;
  final String? assignedDriver;
  final List<LatLng> routePoints;
  final UserRouteOptimizationResult? optimizationResult;
  final bool isLoading;
  final bool isSaving;
  final bool isDeleting;
  final bool isOptimizing;
  final String? errorMessage;
  final UserRouteEffect? effect;

  bool get isBusy => isLoading || isSaving || isDeleting || isOptimizing;

  UserRouteState copyWith({
    List<UserRouteItem>? routes,
    Object? selectedRoute = _unchanged,
    Object? assignedDriver = _unchanged,
    List<LatLng>? routePoints,
    Object? optimizationResult = _unchanged,
    bool? isLoading,
    bool? isSaving,
    bool? isDeleting,
    bool? isOptimizing,
    Object? errorMessage = _unchanged,
    Object? effect = _unchanged,
  }) {
    return UserRouteState(
      routes: routes ?? this.routes,
      selectedRoute: identical(selectedRoute, _unchanged) ? this.selectedRoute : selectedRoute as UserRouteItem?,
      assignedDriver: identical(assignedDriver, _unchanged) ? this.assignedDriver : assignedDriver as String?,
      routePoints: routePoints ?? this.routePoints,
      optimizationResult: identical(optimizationResult, _unchanged) ? this.optimizationResult : optimizationResult as UserRouteOptimizationResult?,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isDeleting: isDeleting ?? this.isDeleting,
      isOptimizing: isOptimizing ?? this.isOptimizing,
      errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
      effect: identical(effect, _unchanged) ? this.effect : effect as UserRouteEffect?,
    );
  }
}

const Object _unchanged = Object();

final userRouteControllerProvider = StateNotifierProvider.autoDispose<UserRouteController, UserRouteState>((ref) => UserRouteController(ref));

class UserRouteController extends StateNotifier<UserRouteState> {
  UserRouteController(this._ref) : super(const UserRouteState());
  final Ref _ref;

  Future<void> loadRoutes() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, errorMessage: null, effect: null);
    final result = await _ref.read(getUserRoutesUseCaseProvider)();
    if (!mounted) return;
    result.when(
      success: (routes) {
        final sorted = List<UserRouteItem>.from(routes)..sort(_latestFirst);
        final latest = sorted.isEmpty ? null : sorted.first;
        state = state.copyWith(
          routes: sorted,
          selectedRoute: latest,
          assignedDriver: latest?.assignedDriver,
          routePoints: latest?.coordinates ?? const <LatLng>[],
          optimizationResult: latest == null
              ? null
              : UserRouteOptimizationResult(
                  points: latest.coordinates,
                  totalDistanceKm: _calculateTotalDistance(latest.coordinates),
                ),
          isLoading: false,
          errorMessage: null,
        );
      },
      failure: (error) {
        final message = _message(error, "Couldn't load routes.");
        state = state.copyWith(
          isLoading: false,
          errorMessage: message,
          effect: UserRouteEffect.error(message),
        );
      },
    );
  }

  Future<bool> createRoute(CreateUserRouteInput input) async {
    if (state.isSaving) return false;
    if (!input.canPersist) {
      final message = 'Route must contain at least two points.';
      state = state.copyWith(errorMessage: message, effect: UserRouteEffect.error(message));
      return false;
    }
    state = state.copyWith(isSaving: true, errorMessage: null, effect: null);
    final result = await _ref.read(createUserRouteUseCaseProvider)(input);
    if (!mounted) return false;
    return result.when(
      success: (route) {
        state = state.copyWith(
          routes: _upsertRoute(state.routes, route),
          selectedRoute: route,
          assignedDriver: route.assignedDriver ?? input.assignedDriver,
          routePoints: input.points,
          isSaving: false,
          effect: const UserRouteEffect.success('Route saved'),
        );
        return true;
      },
      failure: (error) {
        final message = _message(error, "Couldn't save route.");
        state = state.copyWith(isSaving: false, errorMessage: message, effect: UserRouteEffect.error(message));
        return false;
      },
    );
  }

  Future<bool> updateRoute(UpdateUserRouteInput input) async {
    if (state.isSaving) return false;
    if (!input.canPersist) {
      final message = 'Route must contain at least two points.';
      state = state.copyWith(errorMessage: message, effect: UserRouteEffect.error(message));
      return false;
    }
    state = state.copyWith(isSaving: true, errorMessage: null, effect: null);
    final result = await _ref.read(updateUserRouteUseCaseProvider)(input);
    if (!mounted) return false;
    return result.when(
      success: (route) {
        state = state.copyWith(
          routes: _upsertRoute(state.routes, route),
          selectedRoute: route,
          assignedDriver: route.assignedDriver ?? input.assignedDriver,
          routePoints: input.points,
          isSaving: false,
          effect: const UserRouteEffect.success('Route updated'),
        );
        return true;
      },
      failure: (error) {
        final message = _message(error, "Couldn't update route.");
        state = state.copyWith(isSaving: false, errorMessage: message, effect: UserRouteEffect.error(message));
        return false;
      },
    );
  }

  Future<bool> deleteRoute(String routeId) async {
    if (state.isDeleting) return false;
    final id = routeId.trim();
    if (id.isEmpty) {
      state = state.copyWith(
        selectedRoute: null,
        routePoints: const <LatLng>[],
        optimizationResult: null,
        assignedDriver: null,
        effect: const UserRouteEffect.success('Route cleared'),
      );
      return true;
    }
    state = state.copyWith(isDeleting: true, errorMessage: null, effect: null);
    final result = await _ref.read(deleteUserRouteUseCaseProvider)(id);
    if (!mounted) return false;
    return result.when(
      success: (_) {
        state = state.copyWith(
          routes: state.routes.where((route) => route.id != id).toList(growable: false),
          selectedRoute: null,
          assignedDriver: null,
          routePoints: const <LatLng>[],
          optimizationResult: null,
          isDeleting: false,
          effect: const UserRouteEffect.success('Route cleared'),
        );
        return true;
      },
      failure: (error) {
        final message = _message(error, "Couldn't clear route.");
        state = state.copyWith(isDeleting: false, errorMessage: message, effect: UserRouteEffect.error(message));
        return false;
      },
    );
  }

  void selectRoute(String routeId) {
    final id = routeId.trim();
    UserRouteItem? selected;
    for (final route in state.routes) {
      if (route.id == id) {
        selected = route;
        break;
      }
    }
    state = state.copyWith(
      selectedRoute: selected,
      assignedDriver: selected?.assignedDriver,
      routePoints: selected?.coordinates ?? const <LatLng>[],
      optimizationResult: selected == null
          ? null
          : UserRouteOptimizationResult(
              points: selected.coordinates,
              totalDistanceKm: _calculateTotalDistance(selected.coordinates),
            ),
    );
  }

  void setAssignedDriver(String? driver) {
    final normalized = driver?.trim();
    state = state.copyWith(assignedDriver: (normalized == null || normalized.isEmpty) ? null : normalized);
  }

  void setRoutePoints(List<LatLng> points) {
    state = state.copyWith(
      routePoints: List<LatLng>.unmodifiable(points),
      optimizationResult: null,
      errorMessage: null,
    );
  }

  Future<bool> optimizeRoute({
    required List<LatLng> points,
    required String name,
    String color = '#2196F3',
    int toleranceMeters = 100,
  }) async {
    if (state.isOptimizing || state.isSaving) return false;
    state = state.copyWith(isOptimizing: true, errorMessage: null, effect: null);
    final result = _ref.read(optimizeUserRouteUseCaseProvider)(points);
    if (!mounted) return false;

    final optimization = result.when<UserRouteOptimizationResult?>(
      success: (value) => value,
      failure: (error) {
        final message = _message(error, "Couldn't optimize route.");
        state = state.copyWith(isOptimizing: false, errorMessage: message, effect: UserRouteEffect.error(message));
        return null;
      },
    );
    if (optimization == null) return false;

    state = state.copyWith(
      isOptimizing: false,
      routePoints: optimization.points,
      optimizationResult: optimization,
    );

    if (optimization.points.length < 2) {
      state = state.copyWith(effect: UserRouteEffect.success('Optimized route: ${optimization.totalDistanceKm.toStringAsFixed(2)} km'));
      return true;
    }

    final selectedId = state.selectedRoute?.id.trim() ?? '';
    final saved = selectedId.isEmpty
        ? await createRoute(
            CreateUserRouteInput(
              name: name,
              color: color,
              toleranceMeters: toleranceMeters,
              points: optimization.points,
              assignedDriver: state.assignedDriver,
            ),
          )
        : await updateRoute(
            UpdateUserRouteInput(
              routeId: selectedId,
              name: name,
              color: color,
              toleranceMeters: toleranceMeters,
              points: optimization.points,
              assignedDriver: state.assignedDriver,
            ),
          );

    if (!mounted) return false;
    if (saved) {
      state = state.copyWith(effect: UserRouteEffect.success('Optimized route: ${optimization.totalDistanceKm.toStringAsFixed(2)} km'));
    }
    return saved;
  }

  void clearEffect() {
    state = state.copyWith(effect: null);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  int _latestFirst(UserRouteItem a, UserRouteItem b) => _safeParseDate(b.updatedAt).compareTo(_safeParseDate(a.updatedAt));

  DateTime _safeParseDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    final parsed = DateTime.tryParse(value);
    return parsed?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  List<UserRouteItem> _upsertRoute(List<UserRouteItem> routes, UserRouteItem route) {
    final index = routes.indexWhere((item) => item.id == route.id);
    if (index == -1) return <UserRouteItem>[route, ...routes];
    final next = List<UserRouteItem>.from(routes);
    next[index] = route;
    return next;
  }

  double _calculateTotalDistance(List<LatLng> route) {
    final distance = const Distance();
    var total = 0.0;
    for (var i = 0; i < route.length - 1; i++) {
      total += distance.as(LengthUnit.Kilometer, route[i], route[i + 1]);
    }
    return total;
  }

  String _message(Object error, String fallback) => error is AppError && error.message.trim().isNotEmpty ? error.message : fallback;
}
