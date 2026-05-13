// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'superadmin_settings_api_service.dart';

class _SuperadminSettingsApiService implements SuperadminSettingsApiService {
  _SuperadminSettingsApiService(this._dio, {this.baseUrl});

  final Dio _dio;
  final String? baseUrl;

  @override
  Future<ApiResponse<Map<String, dynamic>>> getSettings(String adminId) async {
    final response = await _dio.get<Object?>('/superadmin/settings/$adminId');
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> updateSettings(String adminId, SuperadminSettingsMutationDto body) async {
    final response = await _dio.patch<Object?>('/superadmin/settings/$adminId', data: body.toJson());
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getSuperadminRoles() async {
    final response = await _dio.get<Object?>('/superadmin/roles');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getSuperadminRoleList() async {
    final response = await _dio.get<Object?>('/superadmin/rolelist');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getAdminRoles() async {
    final response = await _dio.get<Object?>('/admin/roles');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getAdminRoleList() async {
    final response = await _dio.get<Object?>('/admin/rolelist');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<void>> updateRole(String roleId, SuperadminRoleMutationDto body) async {
    final response = await _dio.patch<Object?>('/superadmin/roles/$roleId', data: body.toJson());
    return apiDecodeResponse<void>(response.data, (_) {});
  }
}
