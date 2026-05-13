import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:retrofit/retrofit.dart';
import 'package:open_vts/features/admin/data/models/admin_driver_dtos.dart';

part 'admin_driver_api_service.g.dart';

@RestApi()
abstract class AdminDriverApiService {
  factory AdminDriverApiService(Dio dio, {String? baseUrl}) = _AdminDriverApiService;

  @GET('/admin/drivers')
  Future<ApiResponse<List<Map<String, dynamic>>>> getDrivers({
    @Query('search') String? search,
    @Query('status') String? status,
    @Query('page') int? page,
    @Query('limit') int? limit,
  });

  @GET('/admin/drivers/{driverId}')
  Future<ApiResponse<Map<String, dynamic>>> getDriverDetail(@Path('driverId') String driverId);

  @PATCH('/admin/drivers/{driverId}')
  Future<ApiResponse<void>> updateDriver(@Path('driverId') String driverId, @Body() AdminDriverUpdateRequestDto body);

  @GET('/admin/documents/driver/{driverId}')
  Future<ApiResponse<List<Map<String, dynamic>>>> getDriverDocuments(@Path('driverId') String driverId);

  @GET('/admin/drivers/linkedusers/{driverId}')
  Future<ApiResponse<List<Map<String, dynamic>>>> getLinkedUsers(@Path('driverId') String driverId, {@Query('rk') int? rk});

  @GET('/admin/drivers/unlinkedusers/{driverId}')
  Future<ApiResponse<List<Map<String, dynamic>>>> getUnlinkedUsers(@Path('driverId') String driverId, {@Query('rk') int? rk});

  @POST('/admin/drivers/linkedusers/{driverId}')
  Future<ApiResponse<void>> assignUserToDriver(@Path('driverId') String driverId, @Body() AdminDriverUserLinkRequestDto body);

  @POST('/admin/drivers/unlinkedusers/{driverId}')
  Future<ApiResponse<void>> unassignUserFromDriver(@Path('driverId') String driverId, @Body() AdminDriverUserLinkRequestDto body);
}
