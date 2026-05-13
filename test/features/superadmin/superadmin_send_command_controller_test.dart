import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/superadmin/di/superadmin_vehicle_providers.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_vehicle.dart';
import 'package:open_vts/features/superadmin/domain/repositories/superadmin_vehicle_repository.dart';
import 'package:open_vts/features/superadmin/presentation/controllers/superadmin_send_command_controller.dart';

void main() {
  test('send command success emits success effect', () async {
    final container = _container(_FakeVehicleRepository());
    addTearDown(container.dispose);

    final controller = container.read(superadminSendCommandControllerProvider.notifier)
      ..selectCommand('ping')
      ..updatePayload(const <String, Object?>{'interval': 5});
    final ok = await controller.sendCommand('123');

    final state = container.read(superadminSendCommandControllerProvider);
    expect(ok, isTrue);
    expect(state.isSending, isFalse);
    expect(state.effect?.isSuccess, isTrue);
    expect(state.recentCommands, isNotEmpty);
  });

  test('send command failure emits error effect', () async {
    final container = _container(_FakeVehicleRepository(failSend: true));
    addTearDown(container.dispose);

    final ok = await container.read(superadminSendCommandControllerProvider.notifier).sendCommand('123');

    final state = container.read(superadminSendCommandControllerProvider);
    expect(ok, isFalse);
    expect(state.errorMessage, isNotNull);
    expect(state.effect?.isSuccess, isFalse);
  });

  test('double send is blocked', () async {
    final repo = _FakeVehicleRepository(delaySend: true);
    final container = _container(repo);
    addTearDown(container.dispose);

    final controller = container.read(superadminSendCommandControllerProvider.notifier);
    final first = controller.sendCommand('123');
    final second = await controller.sendCommand('123');
    await first;

    expect(second, isFalse);
    expect(repo.sendCalls, 1);
  });

  test('load references success updates options and recent commands', () async {
    final container = _container(_FakeVehicleRepository());
    addTearDown(container.dispose);

    await container.read(superadminSendCommandControllerProvider.notifier).loadReferences('123');

    final state = container.read(superadminSendCommandControllerProvider);
    expect(state.commandOptions, isNotEmpty);
    expect(state.recentCommands, isNotEmpty);
    expect(state.isLoading, isFalse);
  });

  test('clearEffect works', () async {
    final container = _container(_FakeVehicleRepository());
    addTearDown(container.dispose);

    final controller = container.read(superadminSendCommandControllerProvider.notifier);
    await controller.sendCommand('123');
    controller.clearEffect();

    expect(container.read(superadminSendCommandControllerProvider).effect, isNull);
  });
}

ProviderContainer _container(SuperadminVehicleRepository repository) {
  return ProviderContainer(
    overrides: [superadminVehicleRepositoryProvider.overrideWithValue(repository)],
  );
}

class _FakeVehicleRepository implements SuperadminVehicleRepository {
  _FakeVehicleRepository({this.failSend = false, this.delaySend = false});

  final bool failSend;
  final bool delaySend;
  int sendCalls = 0;

  @override
  Future<Result<void, AppError>> sendCommand(String imei, String commandCode, Map<String, Object?>? payload, bool confirm) async {
    sendCalls++;
    if (delaySend) await Future<void>.delayed(const Duration(milliseconds: 10));
    if (failSend) return const Result.failure(ServerError('Send failed'));
    return const Result.success(null);
  }

  @override
  Future<Result<List<SuperadminCommandOption>, AppError>> getCommandOptions(String imei) async {
    return const Result.success([SuperadminCommandOption(id: '1', name: 'ping', code: 'ping', requiresPayload: false)]);
  }

  @override
  Future<Result<List<SuperadminSentCommand>, AppError>> getRecentCommands(String imei) async {
    return const Result.success([SuperadminSentCommand(name: 'ping', status: 'sent', createdAt: 'today')]);
  }

  @override
  Future<Result<List<SuperadminVehicleListItem>, AppError>> getAdminVehicles(String adminId) async => const Result.success([]);
  @override
  Future<Result<SuperadminVehicleDetail, AppError>> getVehicleDetail(String vehicleId) async => Result.success(_detail(vehicleId));
  @override
  Future<Result<List<SuperadminVehicleListItem>, AppError>> getVehicles({int? page, int? limit}) async => const Result.success([]);

  SuperadminVehicleDetail _detail(String id) => SuperadminVehicleDetail(
        id: id,
        name: 'Vehicle',
        plate: 'DL01',
        status: 'active',
        isActive: true,
        imei: '123',
        model: 'GT06',
        type: 'car',
        telemetryUpdatedAt: '',
      );
}
