import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:open_vts/features/admin/data/models/admin_dashboard_response.dart';
import 'package:open_vts/features/vehicles/data/models/vehicle_list_response.dart';
import 'package:retrofit/retrofit.dart';
import 'package:open_vts/core/api/api_response_normalizer.dart';

part 'admin_retrofit_service.g.dart';

@RestApi()
abstract class AdminApiService {
  factory AdminApiService(Dio dio, {String? baseUrl}) = _AdminApiService;

  @GET('/admin/dashboard')
  Future<ApiResponse<AdminDashboardResponse>> getDashboard();

  @GET('/admin/users')
  Future<ApiResponse<AdminUserListResponse>> getUsers({@Query('page') int page = 1, @Query('limit') int limit = 20, @Query('search') String? search});

  @GET('/admin/vehicles')
  Future<ApiResponse<VehicleListResponse>> getVehicles({@Query('page') int page = 1, @Query('limit') int limit = 20, @Query('search') String? search});
}
