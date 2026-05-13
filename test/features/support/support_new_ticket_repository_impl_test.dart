import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/support/data/mappers/support_new_ticket_mapper.dart';
import 'package:open_vts/features/support/data/models/support_new_ticket_dtos.dart';
import 'package:open_vts/features/support/data/repositories/support_new_ticket_repository_impl.dart';
import 'package:open_vts/features/support/data/sources/support_new_ticket_api_service.dart';
import 'package:open_vts/features/support/domain/config/support_role_config.dart';
import 'package:open_vts/features/support/domain/entities/support_models.dart';

void main() {
  test('loadAssignees maps DTOs to domain options', () async {
    final repo = SupportNewTicketRepositoryImpl(
      api: _FakeApi(),
      mapper: const SupportNewTicketMapper(),
    );

    final result = await repo.loadAssignees(SupportRole.admin);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.single.id, 'u1');
  });

  test('create user ticket maps action false to ServerError', () async {
    final repo = SupportNewTicketRepositoryImpl(
      api: _FakeApi(createResponse: _response<Object?>(false, 'Nope', null)),
      mapper: const SupportNewTicketMapper(),
    );

    final result = await repo.createTicket(
      role: SupportRole.user,
      forMyTickets: false,
      draft: const SupportCreateTicketDraft(title: 'Help', message: 'Need help'),
    );

    expect(result.isFailure, isTrue);
    expect(result.errorOrNull, isA<ServerError>());
  });
}

class _FakeApi implements SupportNewTicketApiService {
  _FakeApi({this.createResponse});

  final ApiResponse<Object?>? createResponse;

  @override
  Future<ApiResponse<Object?>> createAdminMyTicket(Object body) async {
    return createResponse ?? _response<Object?>(true, '', null);
  }

  @override
  Future<ApiResponse<Object?>> createAdminUserTicket(
    CreateSupportTicketRequestDto body,
  ) async {
    return createResponse ?? _response<Object?>(true, '', null);
  }

  @override
  Future<ApiResponse<Object?>> createSuperadminTicket(
    CreateSupportTicketRequestDto body,
  ) async {
    return createResponse ?? _response<Object?>(true, '', null);
  }

  @override
  Future<ApiResponse<Object?>> createUserTicket(
    CreateSupportTicketRequestDto body,
  ) async {
    return createResponse ?? _response<Object?>(true, '', null);
  }

  @override
  Future<ApiResponse<SupportAssigneeListResponseDto>> getAdminUsers({
    int limit = 200,
  }) async {
    return _response<SupportAssigneeListResponseDto>(
      true,
      '',
      const SupportAssigneeListResponseDto([
        SupportAssigneeDto(id: 'u1', name: 'User One', role: 'USER'),
      ]),
    );
  }

  @override
  Future<ApiResponse<SupportAssigneeListResponseDto>> getSuperadminAdmins({
    int limit = 200,
  }) async {
    return _response<SupportAssigneeListResponseDto>(
      true,
      '',
      const SupportAssigneeListResponseDto([
        SupportAssigneeDto(id: 'a1', name: 'Admin One', role: 'ADMIN'),
      ]),
    );
  }
}

ApiResponse<T> _response<T>(bool action, String message, T? data) {
  return ApiResponse<T>(
    status: 'success',
    data: ApiData<T>(action: action, message: message, data: data),
    timestamp: null,
  );
}
