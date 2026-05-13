import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:open_vts/features/superadmin/data/models/superadmin_admins_response.dart';
import 'package:retrofit/retrofit.dart';
import 'package:open_vts/core/api/api_response_normalizer.dart';

part 'superadmin_retrofit_service.g.dart';

@RestApi()
abstract class SuperadminApiService {
  factory SuperadminApiService(Dio dio, {String? baseUrl}) = _SuperadminApiService;

  @GET('/superadmin/dashboard')
  Future<ApiResponse<SuperadminDashboardResponse>> getDashboard();

  @GET('/superadmin/admins')
  Future<ApiResponse<SuperadminAdminsResponse>> getAdmins({@Query('page') int page = 1, @Query('limit') int limit = 20, @Query('search') String? search});
}
