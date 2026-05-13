import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:retrofit/retrofit.dart';
import 'package:open_vts/features/admin/data/models/admin_workflow_dtos.dart';

part 'admin_workflow_api_service.g.dart';

@RestApi()
abstract class AdminWorkflowApiService {
  factory AdminWorkflowApiService(Dio dio, {String? baseUrl}) = _AdminWorkflowApiService;

  @GET('/admin/users')
  Future<ApiResponse<List<Map<String, dynamic>>>> getUsers({
    @Query('limit') int limit = 200,
  });

  @POST('/user/drivers')
  Future<ApiResponse<Map<String, dynamic>>> createDriver(@Body() CreateAdminDriverRequestDto body);

  @GET('/devicestypes')
  Future<ApiResponse<List<Map<String, dynamic>>>> getDeviceTypes();

  @GET('/admin/simcards')
  Future<ApiResponse<List<Map<String, dynamic>>>> getSims();

  @POST('/admin/devices')
  Future<ApiResponse<Map<String, dynamic>>> createDevice(@Body() CreateAdminDeviceRequestDto body);

  @POST('/admin/teams')
  Future<ApiResponse<void>> createTeam(@Body() CreateAdminTeamRequestDto body);
}
