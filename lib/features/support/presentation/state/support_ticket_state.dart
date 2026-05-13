import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/support/domain/entities/support_models.dart';

part 'support_ticket_state.freezed.dart';

@freezed
abstract class SupportTicketState with _$SupportTicketState {
  const factory SupportTicketState.initial() = _Initial;
  const factory SupportTicketState.loading() = _Loading;
  const factory SupportTicketState.loaded({@Default(<SupportTicketSummary>[]) List<SupportTicketSummary> tickets}) = _Loaded;
  const factory SupportTicketState.empty() = _Empty;
  const factory SupportTicketState.submitting() = _Submitting;
  const factory SupportTicketState.created(SupportTicketSummary ticket) = _Created;
  const factory SupportTicketState.error(AppError error) = _Error;
}
