// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_device_api_service.dart';

class _AdminDeviceApiService implements AdminDeviceApiService {
  _AdminDeviceApiService(this._dio, {this.baseUrl});

  final Dio _dio;
  final String? baseUrl;

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getDevices({String? search, String? status, int? page, int? limit}) async {
    final query = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) query['search'] = search.trim();
    if (status != null && status.trim().isNotEmpty) query['status'] = status.trim();
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;
    final response = await _dio.get<Object?>('/admin/devices', queryParameters: query.isEmpty ? null : query);
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getDeviceDetail(String deviceId) async {
    final response = await _dio.get<Object?>('/admin/devices/$deviceId');
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getDeviceTypes() async {
    final response = await _dio.get<Object?>('/devicestypes');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getSims() async {
    final response = await _dio.get<Object?>('/admin/simcards');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getSimProviders() async {
    final response = await _dio.get<Object?>('/simproviders');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getQuickSimCards() async {
    final response = await _dio.get<Object?>('/admin/quicksimcards');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<void>> createSimCard(CreateAdminSimCardRequestDto body) async {
    final response = await _dio.post<Object?>('/admin/simcards', data: body.toJson());
    return apiDecodeResponse<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> createDevice(CreateAdminDeviceRequestDto body) async {
    final response = await _dio.post<Object?>('/admin/devices', data: body.toJson());
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<void>> createDeviceAndSim(CreateAdminDeviceAndSimRequestDto body) async {
    final response = await _dio.post<Object?>('/admin/deviceandsim', data: body.toJson());
    return apiDecodeResponse<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<void>> updateDevice(String deviceId, UpdateAdminDeviceRequestDto body) async {
    final response = await _dio.patch<Object?>('/admin/devices/$deviceId', data: body.toJson());
    return apiDecodeResponse<void>(response.data, (_) {});
  }
}
