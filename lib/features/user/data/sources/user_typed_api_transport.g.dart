// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_typed_api_transport.dart';

class _UserTypedApiService implements UserTypedApiService {
  _UserTypedApiService(this._dio, {this.baseUrl});

  final Dio _dio;
  final String? baseUrl;

  ApiResponse<T> decodeResponse<T>(Object? data, T Function(Object? json) fromJsonT) {
    if (data is Map<String, dynamic>) return ApiResponse<T>.fromJson(data, fromJsonT);
    if (data is Map) return ApiResponse<T>.fromJson(Map<String, dynamic>.from(data.cast()), fromJsonT);
    return ApiResponse<T>(
      status: '',
      timestamp: null,
      data: ApiData<T>(action: false, message: 'Invalid API response', data: null),
    );
  }

  Map<String, dynamic> mapValue(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    if (value is List) return <String, dynamic>{'items': value};
    return const <String, dynamic>{};
  }

  String buildPath(String path) => path.startsWith('/') ? path : '/$path';

  @override
  Future<ApiResponse<Map<String, dynamic>>> getMap(String path, {Map<String, Object?>? query}) async {
    final response = await _dio.get<Object?>(buildPath(path), queryParameters: query);
    return decodeResponse(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> postMap(String path, {TypedApiRequestBody? body, Map<String, Object?>? query}) async {
    final response = await _dio.post<Object?>(buildPath(path), data: body, queryParameters: query);
    return decodeResponse(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> postForm(String path, FormData body, {Map<String, Object?>? query}) async {
    final response = await _dio.post<Object?>(buildPath(path), data: body, queryParameters: query);
    return decodeResponse(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> patchMap(String path, {TypedApiRequestBody? body, Map<String, Object?>? query}) async {
    final response = await _dio.patch<Object?>(buildPath(path), data: body, queryParameters: query);
    return decodeResponse(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> patchForm(String path, FormData body, {Map<String, Object?>? query}) async {
    final response = await _dio.patch<Object?>(buildPath(path), data: body, queryParameters: query);
    return decodeResponse(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> putMap(String path, {TypedApiRequestBody? body, Map<String, Object?>? query}) async {
    final response = await _dio.put<Object?>(buildPath(path), data: body, queryParameters: query);
    return decodeResponse(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> deleteMap(String path, {TypedApiRequestBody? body, Map<String, Object?>? query}) async {
    final response = await _dio.delete<Object?>(buildPath(path), data: body, queryParameters: query);
    return decodeResponse(response.data, mapValue);
  }
}
