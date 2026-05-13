// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_driver_api_service.dart';

class _UserDriverApiService implements UserDriverApiService {
  _UserDriverApiService(this._dio, {this.baseUrl});

  final Dio _dio;
  final String? baseUrl;

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getDrivers() async {
    final response = await _dio.get<Object?>('/user/drivers');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getDriverDetail(String id) async {
    final response = await _dio.get<Object?>('/user/drivers/$id');
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> createDriver(UserDriverMutationDto body) async {
    final response = await _dio.post<Object?>('/user/drivers', data: body.toJson());
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<void>> updateDriver(String id, UserDriverMutationDto body) async {
    final response = await _dio.patch<Object?>('/user/drivers/$id', data: body.toJson());
    return apiDecodeResponse<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<void>> deleteDriver(String id, UserDriverMutationDto body) async {
    final response = await _dio.delete<Object?>('/user/drivers/$id', data: body.toJson());
    return apiDecodeResponse<void>(response.data, (_) {});
  }
}
