// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'support_new_ticket_api_service.dart';

class _SupportNewTicketApiService implements SupportNewTicketApiService {
  _SupportNewTicketApiService(this._dio, {this.baseUrl});

  final Dio _dio;
  final String? baseUrl;

  @override
  Future<ApiResponse<SupportAssigneeListResponseDto>> getAdminUsers({
    int limit = 200,
  }) async {
    final response = await _dio.get<Object?>(
      '/admin/users',
      queryParameters: <String, dynamic>{'limit': limit},
    );
    return ApiResponse<SupportAssigneeListResponseDto>.fromJson(
      ApiResponseNormalizer.dynamicMapOf(response.data),
      SupportAssigneeListResponseDto.fromJson,
    );
  }

  @override
  Future<ApiResponse<SupportAssigneeListResponseDto>> getSuperadminAdmins({
    int limit = 200,
  }) async {
    final response = await _dio.get<Object?>(
      '/superadmin/adminlist',
      queryParameters: <String, dynamic>{'limit': limit},
    );
    return ApiResponse<SupportAssigneeListResponseDto>.fromJson(
      ApiResponseNormalizer.dynamicMapOf(response.data),
      SupportAssigneeListResponseDto.fromJson,
    );
  }

  @override
  Future<ApiResponse<Object?>> createAdminUserTicket(
    CreateSupportTicketRequestDto body,
  ) async {
    final response = await _dio.post<Object?>(
      '/admin/tickets',
      data: body.toJson(),
    );
    return _objectResponse(response.data);
  }

  @override
  Future<ApiResponse<Object?>> createAdminMyTicket(Object body) async {
    final response = await _dio.post<Object?>('/admin/mytickets', data: body);
    return _objectResponse(response.data);
  }

  @override
  Future<ApiResponse<Object?>> createUserTicket(
    CreateSupportTicketRequestDto body,
  ) async {
    final response = await _dio.post<Object?>(
      '/user/tickets',
      data: body.toJson(),
    );
    return _objectResponse(response.data);
  }

  @override
  Future<ApiResponse<Object?>> createSuperadminTicket(
    CreateSupportTicketRequestDto body,
  ) async {
    final response = await _dio.post<Object?>(
      '/superadmin/support/tickets',
      data: body.toJson(),
    );
    return _objectResponse(response.data);
  }
}

ApiResponse<Object?> _objectResponse(Object? raw) {
  return ApiResponse<Object?>.fromJson(ApiResponseNormalizer.dynamicMapOf(raw), (json) => json);
}
