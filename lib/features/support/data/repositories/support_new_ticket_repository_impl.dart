import 'package:dio/dio.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/support/data/mappers/support_new_ticket_mapper.dart';
import 'package:open_vts/features/support/data/models/support_new_ticket_dtos.dart';
import 'package:open_vts/features/support/data/sources/support_new_ticket_api_service.dart';
import 'package:open_vts/features/support/domain/config/support_role_config.dart';
import 'package:open_vts/features/support/domain/entities/support_assignee_option.dart';
import 'package:open_vts/features/support/domain/entities/support_models.dart';
import 'package:open_vts/features/support/domain/repositories/support_new_ticket_repository.dart';

class SupportNewTicketRepositoryImpl implements SupportNewTicketRepository {
  const SupportNewTicketRepositoryImpl({
    required SupportNewTicketApiService api,
    required SupportNewTicketMapper mapper,
  })  : _api = api,
        _mapper = mapper;

  final SupportNewTicketApiService _api;
  final SupportNewTicketMapper _mapper;

  @override
  Future<Result<List<SupportAssigneeOption>, AppError>> loadAssignees(
    SupportRole role,
  ) async {
    if (role == SupportRole.user) {
      return const Result.success(<SupportAssigneeOption>[]);
    }

    try {
      final response = role == SupportRole.superadmin
          ? await _api.getSuperadminAdmins()
          : await _api.getAdminUsers();
      if (!response.action) return Result.failure(ServerError(response.message));
      final payload = response.payload;
      if (payload == null) {
        return const Result.failure(ServerError('Assignee response is empty'));
      }
      return Result.success(
        payload.items
            .map((dto) => _mapper.assignee(
                  dto,
                  fallbackRole: role == SupportRole.admin
                      ? SupportRole.user
                      : SupportRole.admin,
                ))
            .where((item) => item.id.isNotEmpty)
            .toList(),
      );
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void, AppError>> createTicket({
    required SupportRole role,
    required bool forMyTickets,
    required SupportCreateTicketDraft draft,
  }) async {
    try {
      final response = switch (role) {
        SupportRole.admin when forMyTickets => await _api.createAdminMyTicket(
            CreateSupportTicketRequestDto.adminMyTicket(draft).toJson(),
          ),
        SupportRole.admin => await _api.createAdminUserTicket(
            CreateSupportTicketRequestDto.adminUserTicket(draft),
          ),
        SupportRole.user => await _api.createUserTicket(
            CreateSupportTicketRequestDto.userTicket(draft),
          ),
        SupportRole.superadmin => await _api.createSuperadminTicket(
            CreateSupportTicketRequestDto.superadminTicket(draft),
          ),
      };
      if (!response.action) return Result.failure(ServerError(response.message));
      return const Result.success(null);
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }
}
