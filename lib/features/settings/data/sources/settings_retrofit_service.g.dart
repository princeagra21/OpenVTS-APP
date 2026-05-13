// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'settings_retrofit_service.dart';

class _SettingsApiService implements SettingsApiService {
  _SettingsApiService(this._dio, {this.baseUrl});
  final Dio _dio;
  final String? baseUrl;

  @override
  Future<ApiResponse<SettingsResponse>> getSettings() async {
    final response = await _dio.get<Object?>('/settings');
    return ApiResponse<SettingsResponse>.fromJson(ApiResponseNormalizer.dynamicMapOf(response.data), (json) => SettingsResponse.fromJson(ApiResponseNormalizer.dynamicMapOf(json)));
  }

  @override
  Future<ApiResponse<SettingsResponse>> updateSettings(SettingsUpdateRequestDto request) async {
    final response = await _dio.put<Object?>('/settings', data: request.toJson());
    return ApiResponse<SettingsResponse>.fromJson(ApiResponseNormalizer.dynamicMapOf(response.data), (json) => SettingsResponse.fromJson(ApiResponseNormalizer.dynamicMapOf(json)));
  }
}
