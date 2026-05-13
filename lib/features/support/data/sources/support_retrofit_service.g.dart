// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'support_retrofit_service.dart';

class _SupportApiService implements SupportApiService {
  _SupportApiService(this._dio, {this.baseUrl});
  final Dio _dio;
  final String? baseUrl;

  @override
  Future<ApiResponse<SupportTicketListResponse>> getTickets({int page = 1, int limit = 20, String? status}) async {
    final response = await _dio.get<Object?>('/support/tickets', queryParameters: {'page': page, 'limit': limit, if (status != null) 'status': status});
    return ApiResponse<SupportTicketListResponse>.fromJson(ApiResponseNormalizer.dynamicMapOf(response.data), (json) => SupportTicketListResponse.fromJson(ApiResponseNormalizer.dynamicMapOf(json)));
  }

  @override
  Future<ApiResponse<SupportTicketResponse>> getTicket(String id) async {
    final response = await _dio.get<Object?>('/support/tickets/$id');
    return ApiResponse<SupportTicketResponse>.fromJson(ApiResponseNormalizer.dynamicMapOf(response.data), (json) => SupportTicketResponse.fromJson(ApiResponseNormalizer.dynamicMapOf(json)));
  }

  @override
  Future<ApiResponse<SupportTicketResponse>> createTicket(SupportTicketCreateRequestDto request) async {
    final response = await _dio.post<Object?>('/support/tickets', data: request.toJson());
    return ApiResponse<SupportTicketResponse>.fromJson(ApiResponseNormalizer.dynamicMapOf(response.data), (json) => SupportTicketResponse.fromJson(ApiResponseNormalizer.dynamicMapOf(json)));
  }
}
