import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/di/user_landmark_providers.dart';
import 'package:open_vts/features/user/domain/entities/create_user_landmark_input.dart';
import 'package:open_vts/features/user/domain/entities/update_user_landmark_input.dart';
import 'package:open_vts/features/user/domain/entities/user_landmark_item.dart';
import 'package:open_vts/features/user/domain/repositories/user_landmark_repository.dart';
import 'package:open_vts/features/user/presentation/controllers/user_landmark_controller.dart';

void main() {
  test('load success puts landmarks into state', () async {
    final repo = _FakeUserLandmarkRepository();
    final container = _container(repo);
    addTearDown(container.dispose);

    await container.read(userLandmarkControllerProvider.notifier).loadLandmarks();

    final state = container.read(userLandmarkControllerProvider);
    expect(state.landmarks.single.name, 'Warehouse');
    expect(state.isLoading, isFalse);
  });

  test('load failure emits error effect', () async {
    final repo = _FakeUserLandmarkRepository(loadFailure: true);
    final container = _container(repo);
    addTearDown(container.dispose);

    await container.read(userLandmarkControllerProvider.notifier).loadLandmarks();

    final state = container.read(userLandmarkControllerProvider);
    expect(state.effect?.isError, isTrue);
    expect(state.errorMessage, isNotNull);
  });

  test('create update and delete landmark mutate controller state', () async {
    final repo = _FakeUserLandmarkRepository();
    final container = _container(repo);
    addTearDown(container.dispose);
    final controller = container.read(userLandmarkControllerProvider.notifier);

    final created = await controller.createLandmark(const CreateUserLandmarkInput(
      name: 'Depot',
      shape: UserLandmarkShape.circle,
      points: <LatLng>[LatLng(28.6, 77.2)],
      radiusMeters: 30,
    ));
    expect(created, isTrue);
    expect(container.read(userLandmarkControllerProvider).landmarks.first.name, 'Depot');

    final updated = await controller.updateLandmark(const UpdateUserLandmarkInput(
      id: 'created',
      name: 'Depot Updated',
      shape: UserLandmarkShape.circle,
      points: <LatLng>[LatLng(28.6, 77.2)],
      radiusMeters: 30,
    ));
    expect(updated, isTrue);

    final deleted = await controller.deleteLandmark('created');
    expect(deleted, isTrue);
  });

  test('double action protection blocks concurrent create', () async {
    final repo = _FakeUserLandmarkRepository(delayCreate: true);
    final container = _container(repo);
    addTearDown(container.dispose);
    final controller = container.read(userLandmarkControllerProvider.notifier);
    const input = CreateUserLandmarkInput(
      name: 'Depot',
      shape: UserLandmarkShape.circle,
      points: <LatLng>[LatLng(28.6, 77.2)],
      radiusMeters: 30,
    );

    final first = controller.createLandmark(input);
    final second = await controller.createLandmark(input);
    expect(second, isFalse);
    await first;
  });

  test('clearEffect clears effect', () async {
    final repo = _FakeUserLandmarkRepository(loadFailure: true);
    final container = _container(repo);
    addTearDown(container.dispose);
    final controller = container.read(userLandmarkControllerProvider.notifier);

    await controller.loadLandmarks();
    expect(container.read(userLandmarkControllerProvider).effect, isNotNull);
    controller.clearEffect();
    expect(container.read(userLandmarkControllerProvider).effect, isNull);
  });
}

ProviderContainer _container(UserLandmarkRepository repo) {
  return ProviderContainer(overrides: [userLandmarkRepositoryProvider.overrideWithValue(repo)]);
}

class _FakeUserLandmarkRepository implements UserLandmarkRepository {
  _FakeUserLandmarkRepository({this.loadFailure = false, this.delayCreate = false});

  final bool loadFailure;
  final bool delayCreate;

  @override
  Future<Result<List<UserLandmarkItem>, AppError>> getGeofences() async {
    if (loadFailure) return const Result.failure(ServerError('boom'));
    return const Result.success(<UserLandmarkItem>[]);
  }

  @override
  Future<Result<List<UserLandmarkItem>, AppError>> getRoutes() async => const Result.success(<UserLandmarkItem>[]);

  @override
  Future<Result<List<UserLandmarkItem>, AppError>> getPois() async => const Result.success(<UserLandmarkItem>[
        UserLandmarkItem(
          id: 'poi-1',
          name: 'Warehouse',
          shape: UserLandmarkShape.poi,
          points: <LatLng>[LatLng(28.6, 77.2)],
        ),
      ]);

  @override
  Future<Result<UserLandmarkItem, AppError>> createLandmark(CreateUserLandmarkInput input) async {
    if (delayCreate) await Future<void>.delayed(const Duration(milliseconds: 10));
    return Result.success(UserLandmarkItem(id: 'created', name: input.name, shape: input.shape, points: input.points, radiusMeters: input.radiusMeters));
  }

  @override
  Future<Result<UserLandmarkItem, AppError>> updateLandmark(UpdateUserLandmarkInput input) async {
    return Result.success(UserLandmarkItem(id: input.id, name: input.name, shape: input.shape, points: input.points, radiusMeters: input.radiusMeters));
  }

  @override
  Future<Result<void, AppError>> deleteLandmark(String id) async => const Result.success(null);
}
