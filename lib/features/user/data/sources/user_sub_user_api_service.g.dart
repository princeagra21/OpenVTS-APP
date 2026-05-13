// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_sub_user_api_service.dart';

class _UserSubUserApiService implements UserSubUserApiService {
  _UserSubUserApiService(this._dio, {this.baseUrl});

  final Dio _dio;
  final String? baseUrl;

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getSubUsers({int? page, int? limit}) async {
    final query = <String, dynamic>{};
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;
    final response = await _dio.get<Object?>('/user/subusers', queryParameters: query.isEmpty ? null : query);
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getSubUserDetail(String id) async {
    final response = await _dio.get<Object?>('/user/subusers/$id');
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> createSubUser(UserSubUserMutationDto body) async {
    final response = await _dio.post<Object?>('/user/subusers', data: body.toJson());
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> updateSubUser(String id, UserSubUserMutationDto body) async {
    final response = await _dio.patch<Object?>('/user/subusers/$id', data: body.toJson());
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<void>> deleteSubUser(String id) async {
    final response = await _dio.delete<Object?>('/user/subusers/$id');
    return apiDecodeResponse<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getSubUserVehicles(String id) async {
    final response = await _dio.get<Object?>('/user/subusers/$id/vehicles');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<void>> assignVehicle(String id, UserSubUserMutationDto body) async {
    final response = await _dio.post<Object?>('/user/subusers/$id/vehicles/assign', data: body.toJson());
    return apiDecodeResponse<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<void>> unassignVehicle(String id, UserSubUserMutationDto body) async {
    final response = await _dio.post<Object?>('/user/subusers/$id/vehicles/unassign', data: body.toJson());
    return apiDecodeResponse<void>(response.data, (_) {});
  }
}
