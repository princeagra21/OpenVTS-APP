import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/support/di/support_new_ticket_controller_provider.dart';
import 'package:open_vts/features/support/domain/config/support_role_config.dart';
import 'package:open_vts/features/support/domain/entities/support_assignee_option.dart';
import 'package:open_vts/features/support/domain/entities/support_models.dart';
import 'package:open_vts/features/support/domain/repositories/support_new_ticket_repository.dart';
import 'package:open_vts/features/support/presentation/new_ticket/new_ticket_controller.dart';

void main() {
  test('loads admin assignees through Riverpod controller', () async {
    final repo = _FakeSupportNewTicketRepository();
    final container = ProviderContainer(overrides: [
      supportNewTicketRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    const args = NewTicketArgs(role: SupportRole.admin);
    container.read(newTicketControllerProvider(args));
    await Future<void>.delayed(Duration.zero);

    expect(container.read(newTicketControllerProvider(args)).users.single.id, 'u1');
  });

  test('submit success uses repository once', () async {
    final repo = _FakeSupportNewTicketRepository();
    final container = ProviderContainer(overrides: [
      supportNewTicketRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    const args = NewTicketArgs(role: SupportRole.user);
    final controller = container.read(newTicketControllerProvider(args).notifier);
    final ok = await controller.submit(title: 'Help', message: 'Need help');

    expect(ok, isTrue);
    expect(repo.createCalls, 1);
  });

  test('prevents double submit while in progress', () async {
    final repo = _FakeSupportNewTicketRepository(delay: const Duration(milliseconds: 50));
    final container = ProviderContainer(overrides: [
      supportNewTicketRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    const args = NewTicketArgs(role: SupportRole.user);
    final controller = container.read(newTicketControllerProvider(args).notifier);
    final first = controller.submit(title: 'Help', message: 'Need help');
    final second = await controller.submit(title: 'Help', message: 'Need help');

    expect(second, isFalse);
    expect(await first, isTrue);
    expect(repo.createCalls, 1);
  });

  test('validation failure does not call repository', () async {
    final repo = _FakeSupportNewTicketRepository();
    final container = ProviderContainer(overrides: [
      supportNewTicketRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    const args = NewTicketArgs(role: SupportRole.user);
    final ok = await container
        .read(newTicketControllerProvider(args).notifier)
        .submit(title: '', message: 'Need help');

    expect(ok, isFalse);
    expect(repo.createCalls, 0);
  });

  test('failure is exposed as state error message', () async {
    final repo = _FakeSupportNewTicketRepository(
      createResult: const Result.failure(ServerError('Server down')),
    );
    final container = ProviderContainer(overrides: [
      supportNewTicketRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    const args = NewTicketArgs(role: SupportRole.user);
    final ok = await container
        .read(newTicketControllerProvider(args).notifier)
        .submit(title: 'Help', message: 'Need help');

    expect(ok, isFalse);
    expect(container.read(newTicketControllerProvider(args)).errorMessage, 'Server down');
  });
}

class _FakeSupportNewTicketRepository implements SupportNewTicketRepository {
  _FakeSupportNewTicketRepository({
    this.createResult = const Result.success(null),
    this.delay = Duration.zero,
  });

  final Result<void, AppError> createResult;
  final Duration delay;
  int createCalls = 0;

  @override
  Future<Result<void, AppError>> createTicket({
    required SupportRole role,
    required bool forMyTickets,
    required SupportCreateTicketDraft draft,
  }) async {
    createCalls++;
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    return createResult;
  }

  @override
  Future<Result<List<SupportAssigneeOption>, AppError>> loadAssignees(
    SupportRole role,
  ) async {
    return const Result.success([
      SupportAssigneeOption(id: 'u1', name: 'User One', role: 'USER'),
    ]);
  }
}
