// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'user_retrofit_service.dart';

class _UserApiService implements UserApiService {
  _UserApiService(this._dio, {this.baseUrl});
  final Dio _dio;
  final String? baseUrl;

  @override
  Future<ApiResponse<UserDashboardResponse>> getDashboard() async {
    final response = await _dio.get<Object?>('/user/dashboard');
    return ApiResponse<UserDashboardResponse>.fromJson(ApiResponseNormalizer.dynamicMapOf(response.data), (json) => UserDashboardResponse.fromJson(ApiResponseNormalizer.dynamicMapOf(json)));
  }

  @override
  Future<ApiResponse<UserVehicleListResponse>> getVehicles({int page = 1, int limit = 20, String? search}) async {
    final response = await _dio.get<Object?>('/user/vehicles', queryParameters: {'page': page, 'limit': limit, if (search != null) 'search': search});
    return ApiResponse<UserVehicleListResponse>.fromJson(ApiResponseNormalizer.dynamicMapOf(response.data), (json) => UserVehicleListResponse.fromJson(ApiResponseNormalizer.dynamicMapOf(json)));
  }
}
