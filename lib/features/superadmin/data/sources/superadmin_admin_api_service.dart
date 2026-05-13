import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:retrofit/retrofit.dart';
import 'package:open_vts/features/superadmin/data/models/superadmin_admin_dtos.dart';

part 'superadmin_admin_api_service.g.dart';

@RestApi()
abstract class SuperadminAdminApiService {
  factory SuperadminAdminApiService(Dio dio, {String? baseUrl}) = _SuperadminAdminApiService;

  @GET('/superadmin/adminlist')
  Future<ApiResponse<List<Map<String, dynamic>>>> getAdmins({
    @Query('page') int? page,
    @Query('limit') int? limit,
    @Query('status') String? status,
  });

  @GET('/superadmin/admin/{adminId}')
  Future<ApiResponse<Map<String, dynamic>>> getAdminDetail(@Path('adminId') String adminId);

  @POST('/superadmin/createadmin')
  Future<ApiResponse<Map<String, dynamic>>> createAdmin(@Body() SuperadminAdminMutationDto body);

  @POST('/superadmin/updateadmin/{adminId}')
  Future<ApiResponse<Map<String, dynamic>>> updateAdmin(@Path('adminId') String adminId, @Body() SuperadminAdminMutationDto body);

  @POST('/superadmin/activateadmin/{adminId}')
  Future<ApiResponse<void>> activateAdmin(@Path('adminId') String adminId, @Body() SuperadminAdminStatusDto body);

  @POST('/superadmin/adminstatusupdate')
  Future<ApiResponse<void>> updateAdminStatusFallback(@Body() SuperadminAdminMutationDto body);

  @PATCH('/superadmin/companydetails')
  Future<ApiResponse<void>> updateCompanyDetails(@Body() SuperadminCompanyMutationDto body);

  @PATCH('/superadmin/companyconfig/{companyId}')
  Future<ApiResponse<void>> updateCompanyConfig(@Path('companyId') String companyId, @Body() SuperadminCompanyMutationDto body);

  @GET('/superadmin/adminlogin/{adminId}')
  Future<ApiResponse<Map<String, dynamic>>> loginAsAdmin(@Path('adminId') String adminId);
}
