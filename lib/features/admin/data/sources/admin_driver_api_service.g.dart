// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_driver_api_service.dart';

class _AdminDriverApiService implements AdminDriverApiService {
  _AdminDriverApiService(this._dio, {this.baseUrl});

  final Dio _dio;
  final String? baseUrl;

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getDrivers({String? search, String? status, int? page, int? limit}) async {
    final query = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) query['search'] = search.trim();
    if (status != null && status.trim().isNotEmpty) query['status'] = status.trim();
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;
    final response = await _dio.get<Object?>('/admin/drivers', queryParameters: query.isEmpty ? null : query);
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getDriverDetail(String driverId) async {
    final response = await _dio.get<Object?>('/admin/drivers/$driverId');
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<void>> updateDriver(String driverId, AdminDriverUpdateRequestDto body) async {
    final response = await _dio.patch<Object?>('/admin/drivers/$driverId', data: body.toStatusJson());
    return apiDecodeResponse<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getDriverDocuments(String driverId) async {
    final response = await _dio.get<Object?>('/admin/documents/driver/$driverId');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getLinkedUsers(String driverId, {int? rk}) async {
    final response = await _dio.get<Object?>('/admin/drivers/linkedusers/$driverId', queryParameters: rk == null ? null : <String, dynamic>{'rk': rk});
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getUnlinkedUsers(String driverId, {int? rk}) async {
    final response = await _dio.get<Object?>('/admin/drivers/unlinkedusers/$driverId', queryParameters: rk == null ? null : <String, dynamic>{'rk': rk});
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<void>> assignUserToDriver(String driverId, AdminDriverUserLinkRequestDto body) async {
    final response = await _dio.post<Object?>('/admin/drivers/linkedusers/$driverId', data: body.toJson());
    return apiDecodeResponse<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<void>> unassignUserFromDriver(String driverId, AdminDriverUserLinkRequestDto body) async {
    final response = await _dio.post<Object?>('/admin/drivers/unlinkedusers/$driverId', data: body.toJson());
    return apiDecodeResponse<void>(response.data, (_) {});
  }
}
