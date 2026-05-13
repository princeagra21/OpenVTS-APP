import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:retrofit/retrofit.dart';
import 'package:open_vts/features/superadmin/data/models/superadmin_settings_dtos.dart';
import 'package:open_vts/features/superadmin/data/models/superadmin_role_dtos.dart';

part 'superadmin_settings_api_service.g.dart';

@RestApi()
abstract class SuperadminSettingsApiService {
  factory SuperadminSettingsApiService(Dio dio, {String? baseUrl}) = _SuperadminSettingsApiService;

  @GET('/superadmin/settings/{adminId}')
  Future<ApiResponse<Map<String, dynamic>>> getSettings(@Path('adminId') String adminId);

  @PATCH('/superadmin/settings/{adminId}')
  Future<ApiResponse<Map<String, dynamic>>> updateSettings(@Path('adminId') String adminId, @Body() SuperadminSettingsMutationDto body);

  @GET('/superadmin/roles')
  Future<ApiResponse<List<Map<String, dynamic>>>> getSuperadminRoles();

  @GET('/superadmin/rolelist')
  Future<ApiResponse<List<Map<String, dynamic>>>> getSuperadminRoleList();

  @GET('/admin/roles')
  Future<ApiResponse<List<Map<String, dynamic>>>> getAdminRoles();

  @GET('/admin/rolelist')
  Future<ApiResponse<List<Map<String, dynamic>>>> getAdminRoleList();

  @PATCH('/superadmin/roles/{roleId}')
  Future<ApiResponse<void>> updateRole(@Path('roleId') String roleId, @Body() SuperadminRoleMutationDto body);
}
