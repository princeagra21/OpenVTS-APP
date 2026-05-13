// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_vehicle_api_service.dart';

class _UserVehicleApiService implements UserVehicleApiService {
  _UserVehicleApiService(this._dio, {this.baseUrl});

  final Dio _dio;
  final String? baseUrl;

  @override
  Future<ApiResponse<Map<String, dynamic>>> getVehicleDetail(String id) async {
    final response = await _dio.get<Object?>('/user/vehicles/$id');
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }
}
