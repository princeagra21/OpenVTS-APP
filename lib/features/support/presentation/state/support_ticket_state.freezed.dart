// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'support_ticket_state.dart';

mixin _$SupportTicketState {}

class _Initial implements SupportTicketState { const _Initial(); }
class _Loading implements SupportTicketState { const _Loading(); }
class _Loaded implements SupportTicketState { const _Loaded({this.tickets = const <SupportTicketSummary>[]}); final List<SupportTicketSummary> tickets; }
class _Empty implements SupportTicketState { const _Empty(); }
class _Submitting implements SupportTicketState { const _Submitting(); }
class _Created implements SupportTicketState { const _Created(this.ticket); final SupportTicketSummary ticket; }
class _Error implements SupportTicketState { const _Error(this.error); final AppError error; }
