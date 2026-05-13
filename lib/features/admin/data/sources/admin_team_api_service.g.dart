// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_team_api_service.dart';

class _AdminTeamApiService implements AdminTeamApiService {
  _AdminTeamApiService(this._dio, {this.baseUrl});

  final Dio _dio;
  final String? baseUrl;

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getTeams({String? search, int? page, int? limit}) async {
    final query = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) query['search'] = search.trim();
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;
    final response = await _dio.get<Object?>('/admin/teams', queryParameters: query.isEmpty ? null : query);
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getTeamDetail(String teamId) async {
    final response = await _dio.get<Object?>('/admin/teams/$teamId');
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<void>> updateTeam(String teamId, AdminTeamMutationRequestDto body) async {
    final response = await _dio.patch<Object?>('/admin/teams/$teamId', data: body.toJson());
    return apiDecodeResponse<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<void>> createTeam(CreateAdminTeamRequestDto body) async {
    final response = await _dio.post<Object?>('/admin/teams', data: body.toJson());
    return apiDecodeResponse<void>(response.data, (_) {});
  }
}
