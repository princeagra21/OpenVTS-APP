// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_vehicle_form_api_service.dart';

class _UserVehicleFormApiService implements UserVehicleFormApiService {
  _UserVehicleFormApiService(this._dio, {this.baseUrl});

  final Dio _dio;
  final String? baseUrl;

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getVehicleTypes() async {
    final response = await _dio.get<Object?>('/vehicletypes');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<void>> createVehicle(CreateUserVehicleRequestDto body) async {
    final response = await _dio.post<Object?>('/user/vehicles', data: body.toJson());
    return apiDecodeResponse<void>(response.data, (_) {});
  }
}
