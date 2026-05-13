// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_route_api_service.dart';

class _UserRouteApiService implements UserRouteApiService {
  _UserRouteApiService(this._dio, {this.baseUrl});

  final Dio _dio;
  final String? baseUrl;

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getRoutes() async {
    final response = await _dio.get<Object?>('/user/routes');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getRouteDetail(String id) async {
    final response = await _dio.get<Object?>('/user/routes/$id');
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> createRoute(UserRouteMutationDto body) async {
    final response = await _dio.post<Object?>('/user/routes', data: body.toJson());
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> updateRoute(String id, UserRouteMutationDto body) async {
    final response = await _dio.patch<Object?>('/user/routes/$id', data: body.toJson());
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<void>> deleteRoute(String id) async {
    final response = await _dio.delete<Object?>('/user/routes/$id');
    return apiDecodeResponse<void>(response.data, (_) {});
  }
}
