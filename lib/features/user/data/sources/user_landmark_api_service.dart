import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:retrofit/retrofit.dart';
import 'package:open_vts/features/user/data/models/user_landmark_dtos.dart';

part 'user_landmark_api_service.g.dart';

@RestApi()
abstract class UserLandmarkApiService {
  factory UserLandmarkApiService(Dio dio, {String? baseUrl}) = _UserLandmarkApiService;

  @GET('/user/geofences')
  Future<ApiResponse<List<Map<String, dynamic>>>> getGeofences();

  @GET('/user/routes')
  Future<ApiResponse<List<Map<String, dynamic>>>> getRoutes();

  @GET('/user/pois')
  Future<ApiResponse<List<Map<String, dynamic>>>> getPois();

  @POST('/user/geofences')
  Future<ApiResponse<Map<String, dynamic>>> createGeofence(@Body() UserLandmarkMutationDto body);

  @POST('/user/routes')
  Future<ApiResponse<Map<String, dynamic>>> createRoute(@Body() UserLandmarkMutationDto body);

  @POST('/user/pois')
  Future<ApiResponse<Map<String, dynamic>>> createPoi(@Body() UserLandmarkMutationDto body);

  @PUT('/user/geofences/{id}')
  Future<ApiResponse<Map<String, dynamic>>> updateGeofence(@Path('id') String id, @Body() UserLandmarkMutationDto body);

  @PUT('/user/routes/{id}')
  Future<ApiResponse<Map<String, dynamic>>> updateRoute(@Path('id') String id, @Body() UserLandmarkMutationDto body);

  @PUT('/user/pois/{id}')
  Future<ApiResponse<Map<String, dynamic>>> updatePoi(@Path('id') String id, @Body() UserLandmarkMutationDto body);

  @DELETE('/user/geofences/{id}')
  Future<ApiResponse<void>> deleteGeofence(@Path('id') String id);

  @DELETE('/user/routes/{id}')
  Future<ApiResponse<void>> deleteRoute(@Path('id') String id);

  @DELETE('/user/pois/{id}')
  Future<ApiResponse<void>> deletePoi(@Path('id') String id);
}
