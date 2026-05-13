// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'vehicle_retrofit_service.dart';

class _VehicleApiService implements VehicleApiService {
  _VehicleApiService(this._dio, {this.baseUrl});
  final Dio _dio;
  final String? baseUrl;

  @override
  Future<ApiResponse<VehicleListResponse>> getVehicles({int page = 1, int limit = 20, String? search, String? status}) async {
    final response = await _dio.get<Object?>('/admin/vehicles', queryParameters: {
      'page': page,
      'limit': limit,
      if (search != null) 'search': search,
      if (status != null) 'status': status,
    });
    return ApiResponse<VehicleListResponse>.fromJson(ApiResponseNormalizer.dynamicMapOf(response.data), (json) => VehicleListResponse.fromJson(ApiResponseNormalizer.dynamicMapOf(json)));
  }

  @override
  Future<ApiResponse<VehicleResponse>> getVehicleById(int id) async {
    final response = await _dio.get<Object?>('/admin/vehicles/$id');
    return ApiResponse<VehicleResponse>.fromJson(ApiResponseNormalizer.dynamicMapOf(response.data), (json) => VehicleResponse.fromJson(ApiResponseNormalizer.dynamicMapOf(json)));
  }

  @override
  Future<ApiResponse<VehicleResponse>> createVehicle(VehicleMutationRequestDto request) async {
    final response = await _dio.post<Object?>('/admin/vehicles', data: request.toJson());
    return ApiResponse<VehicleResponse>.fromJson(ApiResponseNormalizer.dynamicMapOf(response.data), (json) => VehicleResponse.fromJson(ApiResponseNormalizer.dynamicMapOf(json)));
  }

  @override
  Future<ApiResponse<VehicleResponse>> updateVehicle(int id, VehicleMutationRequestDto request) async {
    final response = await _dio.put<Object?>('/admin/vehicles/$id', data: request.toJson());
    return ApiResponse<VehicleResponse>.fromJson(ApiResponseNormalizer.dynamicMapOf(response.data), (json) => VehicleResponse.fromJson(ApiResponseNormalizer.dynamicMapOf(json)));
  }

  @override
  Future<ApiResponse<void>> deleteVehicle(int id) async {
    final response = await _dio.delete<Object?>('/admin/vehicles/$id');
    return ApiResponse<void>.fromJson(ApiResponseNormalizer.dynamicMapOf(response.data), (_) => null);
  }
}
