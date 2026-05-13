// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_landmark_api_service.dart';

class _UserLandmarkApiService implements UserLandmarkApiService {
  _UserLandmarkApiService(this._dio, {this.baseUrl});

  final Dio _dio;
  final String? baseUrl;

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getGeofences() async {
    final response = await _dio.get<Object?>('/user/geofences');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getRoutes() async {
    final response = await _dio.get<Object?>('/user/routes');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getPois() async {
    final response = await _dio.get<Object?>('/user/pois');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> createGeofence(UserLandmarkMutationDto body) async {
    final response = await _dio.post<Object?>('/user/geofences', data: body.toJson());
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> createRoute(UserLandmarkMutationDto body) async {
    final response = await _dio.post<Object?>('/user/routes', data: body.toJson());
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> createPoi(UserLandmarkMutationDto body) async {
    final response = await _dio.post<Object?>('/user/pois', data: body.toJson());
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> updateGeofence(String id, UserLandmarkMutationDto body) async {
    final response = await _dio.put<Object?>('/user/geofences/$id', data: body.toJson());
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> updateRoute(String id, UserLandmarkMutationDto body) async {
    final response = await _dio.put<Object?>('/user/routes/$id', data: body.toJson());
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> updatePoi(String id, UserLandmarkMutationDto body) async {
    final response = await _dio.put<Object?>('/user/pois/$id', data: body.toJson());
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<void>> deleteGeofence(String id) async {
    final response = await _dio.delete<Object?>('/user/geofences/$id');
    return apiDecodeResponse<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<void>> deleteRoute(String id) async {
    final response = await _dio.delete<Object?>('/user/routes/$id');
    return apiDecodeResponse<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<void>> deletePoi(String id) async {
    final response = await _dio.delete<Object?>('/user/pois/$id');
    return apiDecodeResponse<void>(response.data, (_) {});
  }
}
