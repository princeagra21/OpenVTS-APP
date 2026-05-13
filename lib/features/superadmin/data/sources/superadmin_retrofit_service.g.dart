// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'superadmin_retrofit_service.dart';

class _SuperadminApiService implements SuperadminApiService {
  _SuperadminApiService(this._dio, {this.baseUrl});
  final Dio _dio;
  final String? baseUrl;

  @override
  Future<ApiResponse<SuperadminDashboardResponse>> getDashboard() async {
    final response = await _dio.get<Object?>('/superadmin/dashboard');
    return ApiResponse<SuperadminDashboardResponse>.fromJson(ApiResponseNormalizer.dynamicMapOf(response.data), (json) => SuperadminDashboardResponse.fromJson(ApiResponseNormalizer.dynamicMapOf(json)));
  }

  @override
  Future<ApiResponse<SuperadminAdminsResponse>> getAdmins({int page = 1, int limit = 20, String? search}) async {
    final response = await _dio.get<Object?>('/superadmin/admins', queryParameters: {'page': page, 'limit': limit, if (search != null) 'search': search});
    return ApiResponse<SuperadminAdminsResponse>.fromJson(ApiResponseNormalizer.dynamicMapOf(response.data), (json) => SuperadminAdminsResponse.fromJson(ApiResponseNormalizer.dynamicMapOf(json)));
  }
}
