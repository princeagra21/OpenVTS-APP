// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'superadmin_vehicle_api_service.dart';

class _SuperadminVehicleApiService implements SuperadminVehicleApiService {
  _SuperadminVehicleApiService(this._dio, {this.baseUrl});

  final Dio _dio;
  final String? baseUrl;

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getAdminVehicles(String adminId) async {
    final response = await _dio.get<Object?>('/superadmin/adminvehicles/$adminId');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getVehicles({int? page, int? limit}) async {
    final query = <String, dynamic>{};
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;
    final response = await _dio.get<Object?>('/superadmin/vehicles', queryParameters: query.isEmpty ? null : query);
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getVehicleDetail(String vehicleId) async {
    final response = await _dio.get<Object?>('/superadmin/vehicles/$vehicleId');
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getVehicleByImeiDetail(String imei) async {
    final response = await _dio.get<Object?>('/superadmin/vehicles/by-imei/$imei/details');
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getCommandOptions() async {
    final response = await _dio.get<Object?>('/superadmin/commandtypes');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> sendCommand(SuperadminSendCommandRequestDto body) async {
    final response = await _dio.post<Object?>('/superadmin/customcommands', data: body.toJson());
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getRecentCommands() async {
    final response = await _dio.get<Object?>('/superadmin/customcommands');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }
}
