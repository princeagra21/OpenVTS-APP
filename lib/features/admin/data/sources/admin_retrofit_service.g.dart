// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'admin_retrofit_service.dart';

class _AdminApiService implements AdminApiService {
  _AdminApiService(this._dio, {this.baseUrl});
  final Dio _dio;
  final String? baseUrl;

  @override
  Future<ApiResponse<AdminDashboardResponse>> getDashboard() async {
    final response = await _dio.get<Object?>('/admin/dashboard');
    return ApiResponse<AdminDashboardResponse>.fromJson(ApiResponseNormalizer.dynamicMapOf(response.data), (json) => AdminDashboardResponse.fromJson(ApiResponseNormalizer.dynamicMapOf(json)));
  }

  @override
  Future<ApiResponse<AdminUserListResponse>> getUsers({int page = 1, int limit = 20, String? search}) async {
    final response = await _dio.get<Object?>('/admin/users', queryParameters: {'page': page, 'limit': limit, if (search != null) 'search': search});
    return ApiResponse<AdminUserListResponse>.fromJson(ApiResponseNormalizer.dynamicMapOf(response.data), (json) => AdminUserListResponse.fromJson(ApiResponseNormalizer.dynamicMapOf(json)));
  }

  @override
  Future<ApiResponse<VehicleListResponse>> getVehicles({int page = 1, int limit = 20, String? search}) async {
    final response = await _dio.get<Object?>('/admin/vehicles', queryParameters: {'page': page, 'limit': limit, if (search != null) 'search': search});
    return ApiResponse<VehicleListResponse>.fromJson(ApiResponseNormalizer.dynamicMapOf(response.data), (json) => VehicleListResponse.fromJson(ApiResponseNormalizer.dynamicMapOf(json)));
  }
}
