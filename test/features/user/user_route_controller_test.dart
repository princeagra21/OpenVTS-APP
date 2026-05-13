import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/di/user_route_providers.dart';
import 'package:open_vts/features/user/domain/entities/create_user_route_input.dart';
import 'package:open_vts/features/user/domain/entities/update_user_route_input.dart';
import 'package:open_vts/features/user/domain/entities/user_route_item.dart';
import 'package:open_vts/features/user/domain/repositories/user_route_repository.dart';
import 'package:open_vts/features/user/presentation/controllers/user_route_controller.dart';

void main() {
  test('initial state is idle', () {
    final container = ProviderContainer(overrides: [userRouteRepositoryProvider.overrideWithValue(_FakeUserRouteRepository())]);
    addTearDown(container.dispose);

    final state = container.read(userRouteControllerProvider);

    expect(state.routes, isEmpty);
    expect(state.isBusy, isFalse);
    expect(state.errorMessage, isNull);
  });

  test('load routes success selects latest route', () async {
    final container = ProviderContainer(overrides: [userRouteRepositoryProvider.overrideWithValue(_FakeUserRouteRepository())]);
    addTearDown(container.dispose);

    await container.read(userRouteControllerProvider.notifier).loadRoutes();

    final state = container.read(userRouteControllerProvider);
    expect(state.routes.length, 2);
    expect(state.selectedRoute?.id, 'route-2');
    expect(state.routePoints.length, 2);
    expect(state.isLoading, isFalse);
  });

  test('load routes failure emits error effect', () async {
    final container = ProviderContainer(overrides: [userRouteRepositoryProvider.overrideWithValue(_FakeUserRouteRepository(failLoad: true))]);
    addTearDown(container.dispose);

    await container.read(userRouteControllerProvider.notifier).loadRoutes();

    final state = container.read(userRouteControllerProvider);
    expect(state.errorMessage, 'Load failed');
    expect(state.effect?.isError, isTrue);
  });

  test('create route success stores selected route', () async {
    final repo = _FakeUserRouteRepository();
    final container = ProviderContainer(overrides: [userRouteRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);

    final ok = await container.read(userRouteControllerProvider.notifier).createRoute(_input());

    expect(ok, isTrue);
    expect(repo.createCalls, 1);
    expect(container.read(userRouteControllerProvider).selectedRoute?.id, 'created');
  });

  test('create route failure emits error effect', () async {
    final container = ProviderContainer(overrides: [userRouteRepositoryProvider.overrideWithValue(_FakeUserRouteRepository(failCreate: true))]);
    addTearDown(container.dispose);

    final ok = await container.read(userRouteControllerProvider.notifier).createRoute(_input());

    expect(ok, isFalse);
    expect(container.read(userRouteControllerProvider).effect?.isError, isTrue);
  });

  test('update route success stores updated selected route', () async {
    final repo = _FakeUserRouteRepository();
    final container = ProviderContainer(overrides: [userRouteRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);

    final ok = await container.read(userRouteControllerProvider.notifier).updateRoute(_updateInput('route-1'));

    expect(ok, isTrue);
    expect(repo.updateCalls, 1);
    expect(container.read(userRouteControllerProvider).selectedRoute?.id, 'route-1');
  });

  test('delete route success clears selected route', () async {
    final repo = _FakeUserRouteRepository();
    final container = ProviderContainer(overrides: [userRouteRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);

    await container.read(userRouteControllerProvider.notifier).loadRoutes();
    final ok = await container.read(userRouteControllerProvider.notifier).deleteRoute('route-2');

    expect(ok, isTrue);
    expect(repo.deleteCalls, 1);
    expect(container.read(userRouteControllerProvider).selectedRoute, isNull);
  });

  test('double delete is blocked', () async {
    final repo = _FakeUserRouteRepository(delay: const Duration(milliseconds: 50));
    final container = ProviderContainer(overrides: [userRouteRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);

    final first = container.read(userRouteControllerProvider.notifier).deleteRoute('route-1');
    final second = await container.read(userRouteControllerProvider.notifier).deleteRoute('route-1');

    expect(second, isFalse);
    expect(await first, isTrue);
    expect(repo.deleteCalls, 1);
  });

  test('optimize route success saves route and emits success effect', () async {
    final repo = _FakeUserRouteRepository();
    final container = ProviderContainer(overrides: [userRouteRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);

    final ok = await container.read(userRouteControllerProvider.notifier).optimizeRoute(points: _points(), name: 'Optimized Route');

    expect(ok, isTrue);
    expect(repo.createCalls, 1);
    expect(container.read(userRouteControllerProvider).optimizationResult, isNotNull);
    expect(container.read(userRouteControllerProvider).effect?.isError, isFalse);
  });

  test('clearEffect removes one-shot effect', () async {
    final container = ProviderContainer(overrides: [userRouteRepositoryProvider.overrideWithValue(_FakeUserRouteRepository(failLoad: true))]);
    addTearDown(container.dispose);

    await container.read(userRouteControllerProvider.notifier).loadRoutes();
    container.read(userRouteControllerProvider.notifier).clearEffect();

    expect(container.read(userRouteControllerProvider).effect, isNull);
  });
}

CreateUserRouteInput _input() => CreateUserRouteInput(name: 'Route', points: _points());
UpdateUserRouteInput _updateInput(String id) => UpdateUserRouteInput(routeId: id, name: 'Route', points: _points());
List<LatLng> _points() => const <LatLng>[LatLng(28.61, 77.20), LatLng(28.62, 77.21)];

class _FakeUserRouteRepository implements UserRouteRepository {
  _FakeUserRouteRepository({
    this.failLoad = false,
    this.failCreate = false,
    this.delay = Duration.zero,
  });

  final bool failLoad;
  final bool failCreate;
  final Duration delay;
  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;

  @override
  Future<Result<List<UserRouteItem>, AppError>> getRoutes() async {
    if (failLoad) return const Result.failure(ServerError('Load failed'));
    return Result.success(<UserRouteItem>[
      UserRouteItem(id: 'route-1', name: 'Old Route', color: '#2196F3', toleranceMeters: 100, updatedAt: '2026-01-01T00:00:00Z', coordinates: _points()),
      UserRouteItem(id: 'route-2', name: 'Main Route', color: '#2196F3', toleranceMeters: 100, updatedAt: '2026-01-02T00:00:00Z', coordinates: _points()),
    ]);
  }

  @override
  Future<Result<UserRouteItem, AppError>> createRoute(CreateUserRouteInput input) async {
    createCalls++;
    if (failCreate) return const Result.failure(ServerError('Create failed'));
    return Result.success(UserRouteItem(id: 'created', name: input.name, color: input.color, toleranceMeters: input.toleranceMeters, updatedAt: '2026-01-03T00:00:00Z', coordinates: input.points));
  }

  @override
  Future<Result<UserRouteItem, AppError>> assignRouteDriver(String routeId, String? driver) async {
    return Result.success(UserRouteItem(id: routeId, name: 'Route', color: '#2196F3', toleranceMeters: 100, updatedAt: '2026-01-03T00:00:00Z', coordinates: _points(), assignedDriver: driver));
  }

  @override
  Future<Result<UserRouteItem, AppError>> updateRoute(UpdateUserRouteInput input) async {
    updateCalls++;
    return Result.success(UserRouteItem(id: input.routeId, name: input.name, color: input.color, toleranceMeters: input.toleranceMeters, updatedAt: '2026-01-04T00:00:00Z', coordinates: input.points));
  }

  @override
  Future<Result<void, AppError>> deleteRoute(String routeId) async {
    deleteCalls++;
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    return const Result.success(null);
  }
}
