import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:retrofit/retrofit.dart';
import 'package:open_vts/features/user/data/models/user_route_dtos.dart';

part 'user_route_api_service.g.dart';

@RestApi()
abstract class UserRouteApiService {
  factory UserRouteApiService(Dio dio, {String? baseUrl}) = _UserRouteApiService;

  @GET('/user/routes')
  Future<ApiResponse<List<Map<String, dynamic>>>> getRoutes();

  @GET('/user/routes/{id}')
  Future<ApiResponse<Map<String, dynamic>>> getRouteDetail(@Path('id') String id);

  @POST('/user/routes')
  Future<ApiResponse<Map<String, dynamic>>> createRoute(@Body() UserRouteMutationDto body);

  @PATCH('/user/routes/{id}')
  Future<ApiResponse<Map<String, dynamic>>> updateRoute(@Path('id') String id, @Body() UserRouteMutationDto body);

  @DELETE('/user/routes/{id}')
  Future<ApiResponse<void>> deleteRoute(@Path('id') String id);
}
