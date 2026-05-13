import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:retrofit/retrofit.dart';
import 'package:open_vts/features/admin/data/models/admin_form_dtos.dart';

part 'admin_form_api_service.g.dart';

@RestApi()
abstract class AdminFormApiService {
  factory AdminFormApiService(Dio dio, {String? baseUrl}) = _AdminFormApiService;

  @GET('/admin/users')
  Future<ApiResponse<List<Map<String, dynamic>>>> getUsers({
    @Query('limit') int limit = 100,
  });

  @GET('/admin/quickdevice')
  Future<ApiResponse<List<Map<String, dynamic>>>> getQuickDevices();

  @GET('/vehicletypes')
  Future<ApiResponse<List<Map<String, dynamic>>>> getVehicleTypes();

  @GET('/admin/pricingplans')
  Future<ApiResponse<List<Map<String, dynamic>>>> getPricingPlans();

  @POST('/admin/users')
  Future<ApiResponse<Map<String, dynamic>>> createUser(@Body() CreateAdminUserRequestDto body);

  @POST('/admin/vehicles')
  Future<ApiResponse<void>> createVehicle(@Body() CreateAdminVehicleRequestDto body);
}
