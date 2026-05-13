// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_workflow_api_service.dart';

class _AdminWorkflowApiService implements AdminWorkflowApiService {
  _AdminWorkflowApiService(this._dio, {this.baseUrl});

  final Dio _dio;
  final String? baseUrl;

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getUsers({int limit = 200}) async {
    final response = await _dio.get<Object?>(
      '/admin/users',
      queryParameters: <String, dynamic>{'limit': limit},
    );
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> createDriver(CreateAdminDriverRequestDto body) async {
    final response = await _dio.post<Object?>('/user/drivers', data: body.toJson());
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getDeviceTypes() async {
    final response = await _dio.get<Object?>('/devicestypes');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getSims() async {
    final response = await _dio.get<Object?>('/admin/simcards');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> createDevice(CreateAdminDeviceRequestDto body) async {
    final response = await _dio.post<Object?>('/admin/devices', data: body.toJson());
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<void>> createTeam(CreateAdminTeamRequestDto body) async {
    final response = await _dio.post<Object?>('/admin/teams', data: body.toJson());
    return apiDecodeResponse<void>(response.data, (_) {});
  }
}
