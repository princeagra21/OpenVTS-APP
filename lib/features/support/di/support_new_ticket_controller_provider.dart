import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/network/dio_provider.dart';
import 'package:open_vts/features/support/data/mappers/support_new_ticket_mapper.dart';
import 'package:open_vts/features/support/data/repositories/support_new_ticket_repository_impl.dart';
import 'package:open_vts/features/support/data/sources/support_new_ticket_api_service.dart';
import 'package:open_vts/features/support/domain/repositories/support_new_ticket_repository.dart';
import 'package:open_vts/features/support/domain/use_cases/create_new_support_ticket_use_case.dart';
import 'package:open_vts/features/support/domain/use_cases/load_support_assignees_use_case.dart';
import 'package:open_vts/features/support/presentation/new_ticket/new_ticket_controller.dart';
import 'package:open_vts/features/support/presentation/new_ticket/new_ticket_state.dart';

final supportNewTicketApiServiceProvider = Provider<SupportNewTicketApiService>((ref) {
  return SupportNewTicketApiService(ref.watch(appDioProvider));
});

final supportNewTicketMapperProvider = Provider<SupportNewTicketMapper>((ref) {
  return const SupportNewTicketMapper();
});

final supportNewTicketRepositoryProvider = Provider<SupportNewTicketRepository>((ref) {
  return SupportNewTicketRepositoryImpl(
    api: ref.watch(supportNewTicketApiServiceProvider),
    mapper: ref.watch(supportNewTicketMapperProvider),
  );
});

final loadSupportAssigneesUseCaseProvider = Provider<LoadSupportAssigneesUseCase>((ref) {
  return LoadSupportAssigneesUseCase(ref.watch(supportNewTicketRepositoryProvider));
});

final createNewSupportTicketUseCaseProvider = Provider<CreateNewSupportTicketUseCase>((ref) {
  return CreateNewSupportTicketUseCase(ref.watch(supportNewTicketRepositoryProvider));
});

final newTicketControllerProvider = StateNotifierProvider.autoDispose
    .family<NewTicketController, NewTicketState, NewTicketArgs>((ref, args) {
  return NewTicketController(
    args: args,
    loadAssigneesUseCase: ref.watch(loadSupportAssigneesUseCaseProvider),
    createTicketUseCase: ref.watch(createNewSupportTicketUseCaseProvider),
  );
});
