import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:retrofit/retrofit.dart';
import 'package:open_vts/features/user/data/models/user_sub_user_dtos.dart';

part 'user_sub_user_api_service.g.dart';

@RestApi()
abstract class UserSubUserApiService {
  factory UserSubUserApiService(Dio dio, {String? baseUrl}) = _UserSubUserApiService;

  @GET('/user/subusers')
  Future<ApiResponse<List<Map<String, dynamic>>>> getSubUsers({@Query('page') int? page, @Query('limit') int? limit});

  @GET('/user/subusers/{id}')
  Future<ApiResponse<Map<String, dynamic>>> getSubUserDetail(@Path('id') String id);

  @POST('/user/subusers')
  Future<ApiResponse<Map<String, dynamic>>> createSubUser(@Body() UserSubUserMutationDto body);

  @PATCH('/user/subusers/{id}')
  Future<ApiResponse<Map<String, dynamic>>> updateSubUser(@Path('id') String id, @Body() UserSubUserMutationDto body);

  @DELETE('/user/subusers/{id}')
  Future<ApiResponse<void>> deleteSubUser(@Path('id') String id);

  @GET('/user/subusers/{id}/vehicles')
  Future<ApiResponse<List<Map<String, dynamic>>>> getSubUserVehicles(@Path('id') String id);

  @POST('/user/subusers/{id}/vehicles/assign')
  Future<ApiResponse<void>> assignVehicle(@Path('id') String id, @Body() UserSubUserMutationDto body);

  @POST('/user/subusers/{id}/vehicles/unassign')
  Future<ApiResponse<void>> unassignVehicle(@Path('id') String id, @Body() UserSubUserMutationDto body);
}
