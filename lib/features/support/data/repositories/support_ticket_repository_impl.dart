import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/support/data/mappers/support_ticket_mapper.dart';
import 'package:open_vts/features/support/data/sources/support_retrofit_service.dart';
import 'package:open_vts/features/support/domain/entities/support_models.dart';
import 'package:open_vts/features/support/domain/repositories/support_ticket_repository.dart';
import 'package:open_vts/features/support/data/models/support_ticket_request_dto.dart';

class SupportTicketRepositoryImpl implements SupportTicketRepository {
  const SupportTicketRepositoryImpl({required SupportApiService api, SupportTicketMapper mapper = const SupportTicketMapper()})
      : _api = api,
        _mapper = mapper;

  final SupportApiService _api;
  final SupportTicketMapper _mapper;

  @override
  Future<Result<List<SupportTicketSummary>, AppError>> getTickets() async {
    try {
      final response = await _api.getTickets();
      final payload = response.payload;
      if (!response.action || payload == null) {
        return Result.failure(ServerError(response.message.isEmpty ? 'Unable to load support tickets.' : response.message));
      }
      return Result.success(payload.items.map(_mapper.fromMap).toList(growable: false));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<SupportTicketSummary, AppError>> createTicket({
    required String subject,
    required String message,
    String? category,
    String? priority,
  }) async {
    try {
      final response = await _api.createTicket(SupportTicketCreateRequestDto(subject: subject, message: message, category: category, priority: priority));
      final payload = response.payload;
      if (!response.action || payload == null) {
        return Result.failure(ServerError(response.message.isEmpty ? 'Unable to create ticket.' : response.message));
      }
      return Result.success(_mapper.toSummary(payload));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }
}
