import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/support/di/support_providers.dart';
import 'package:open_vts/features/support/domain/config/support_role_config.dart';
import 'package:open_vts/features/support/domain/use_cases/create_support_ticket_use_case.dart';
import 'package:open_vts/features/support/presentation/new_ticket/new_ticket_state.dart';
import 'package:open_vts/features/support/presentation/state/support_ticket_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'support_riverpod_providers.g.dart';

@riverpod
class SupportTicketNotifier extends _$SupportTicketNotifier {
  @override
  SupportTicketState build(SupportRole role) => const SupportTicketState.initial();

  Future<void> load() async {
    state = const SupportTicketState.loading();
    final result = await ref.read(getSupportTicketsUseCaseProvider)();
    state = result.when(
      success: (tickets) => tickets.isEmpty ? const SupportTicketState.empty() : SupportTicketState.loaded(tickets: tickets),
      failure: SupportTicketState.error,
    );
  }

  Future<void> create({required String subject, required String message, String? category, String? priority}) async {
    state = const SupportTicketState.submitting();
    final result = await ref.read(createSupportTicketUseCaseProvider)(
          CreateSupportTicketParams(subject: subject, message: message, category: category, priority: priority),
        );
    state = result.when(
      success: (ticket) => SupportTicketState.created(ticket),
      failure: SupportTicketState.error,
    );
  }
}

@riverpod
class NewTicketFormNotifier extends _$NewTicketFormNotifier {
  @override
  NewTicketState build(SupportRole role) => NewTicketState(role: role);

  void setSubmitting(bool value) => state = state.copyWith(submitting: value);
}
