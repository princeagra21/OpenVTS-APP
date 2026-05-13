import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:open_vts/features/user/data/models/user_dashboard_response.dart';
import 'package:retrofit/retrofit.dart';
import 'package:open_vts/core/api/api_response_normalizer.dart';

part 'user_retrofit_service.g.dart';

@RestApi()
abstract class UserApiService {
  factory UserApiService(Dio dio, {String? baseUrl}) = _UserApiService;

  @GET('/user/dashboard')
  Future<ApiResponse<UserDashboardResponse>> getDashboard();

  @GET('/user/vehicles')
  Future<ApiResponse<UserVehicleListResponse>> getVehicles({@Query('page') int page = 1, @Query('limit') int limit = 20, @Query('search') String? search});
}
