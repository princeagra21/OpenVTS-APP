// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_vehicle_api_service.dart';

class _AdminVehicleApiService implements AdminVehicleApiService {
  _AdminVehicleApiService(this._dio, {this.baseUrl});

  final Dio _dio;
  final String? baseUrl;

  @override
  Future<ApiResponse<Map<String, dynamic>>> getVehicleDetail(String vehicleId) async {
    final response = await _dio.get<Object?>('/admin/vehicles/$vehicleId');
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getLinkedUsers(String vehicleId) async {
    final response = await _dio.get<Object?>('/admin/linkusers/$vehicleId');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getVehicleDocuments(String vehicleId) async {
    final response = await _dio.get<Object?>('/admin/documents/vehicle/$vehicleId');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getVehicleConfig(String vehicleId) async {
    final response = await _dio.get<Object?>('/admin/vehicles/$vehicleId/config');
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<void>> updateVehicleConfig(String vehicleId, AdminVehicleConfigUpdateRequestDto body) async {
    final response = await _dio.patch<Object?>('/admin/vehicles/$vehicleId/config', data: body.toJson());
    return apiDecodeResponse<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getVehicleLogsByImei(String imei, {Map<String, Object?>? query}) async {
    final response = await _dio.get<Object?>('/admin/vehicles/by-imei/$imei/logs', queryParameters: query);
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<void>> updateVehicle(String vehicleId, UpdateAdminVehicleStatusRequestDto body) async {
    final response = await _dio.patch<Object?>('/admin/vehicles/$vehicleId', data: body.toJson());
    return apiDecodeResponse<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<void>> deleteVehicle(String vehicleId) async {
    final response = await _dio.delete<Object?>('/admin/vehicles/$vehicleId');
    return apiDecodeResponse<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<void>> assignDriver(String vehicleId, AdminVehicleDriverAssignmentRequestDto body) async {
    final response = await _dio.post<Object?>('/admin/vehicles/$vehicleId/driver', data: body.toJson());
    return apiDecodeResponse<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<void>> unassignDriver(String vehicleId) async {
    final response = await _dio.delete<Object?>('/admin/vehicles/$vehicleId/driver');
    return apiDecodeResponse<void>(response.data, (_) {});
  }
}
