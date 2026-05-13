// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_form_api_service.dart';

class _AdminFormApiService implements AdminFormApiService {
  _AdminFormApiService(this._dio, {this.baseUrl});

  final Dio _dio;
  final String? baseUrl;

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getUsers({int limit = 100}) async {
    final response = await _dio.get<Object?>(
      '/admin/users',
      queryParameters: <String, dynamic>{'limit': limit},
    );
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getQuickDevices() async {
    final response = await _dio.get<Object?>('/admin/quickdevice');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getVehicleTypes() async {
    final response = await _dio.get<Object?>('/vehicletypes');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getPricingPlans() async {
    final response = await _dio.get<Object?>('/admin/pricingplans');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> createUser(CreateAdminUserRequestDto body) async {
    final response = await _dio.post<Object?>('/admin/users', data: body.toJson());
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<void>> createVehicle(CreateAdminVehicleRequestDto body) async {
    final response = await _dio.post<Object?>('/admin/vehicles', data: body.toJson());
    return apiDecodeResponse<void>(response.data, (_) {});
  }
}
