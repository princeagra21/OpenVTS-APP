import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:retrofit/retrofit.dart';
import 'package:open_vts/features/admin/data/models/admin_team_dtos.dart';

part 'admin_team_api_service.g.dart';

@RestApi()
abstract class AdminTeamApiService {
  factory AdminTeamApiService(Dio dio, {String? baseUrl}) = _AdminTeamApiService;

  @GET('/admin/teams')
  Future<ApiResponse<List<Map<String, dynamic>>>> getTeams({
    @Query('search') String? search,
    @Query('page') int? page,
    @Query('limit') int? limit,
  });

  @GET('/admin/teams/{teamId}')
  Future<ApiResponse<Map<String, dynamic>>> getTeamDetail(@Path('teamId') String teamId);

  @PATCH('/admin/teams/{teamId}')
  Future<ApiResponse<void>> updateTeam(@Path('teamId') String teamId, @Body() AdminTeamMutationRequestDto body);

  @POST('/admin/teams')
  Future<ApiResponse<void>> createTeam(@Body() CreateAdminTeamRequestDto body);
}
