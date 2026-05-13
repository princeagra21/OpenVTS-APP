import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:retrofit/retrofit.dart';
import 'package:open_vts/features/admin/data/models/admin_device_dtos.dart';

part 'admin_device_api_service.g.dart';

@RestApi()
abstract class AdminDeviceApiService {
  factory AdminDeviceApiService(Dio dio, {String? baseUrl}) = _AdminDeviceApiService;

  @GET('/admin/devices')
  Future<ApiResponse<List<Map<String, dynamic>>>> getDevices({
    @Query('search') String? search,
    @Query('status') String? status,
    @Query('page') int? page,
    @Query('limit') int? limit,
  });

  @GET('/admin/devices/{deviceId}')
  Future<ApiResponse<Map<String, dynamic>>> getDeviceDetail(@Path('deviceId') String deviceId);

  @GET('/devicestypes')
  Future<ApiResponse<List<Map<String, dynamic>>>> getDeviceTypes();

  @GET('/admin/simcards')
  Future<ApiResponse<List<Map<String, dynamic>>>> getSims();

  @GET('/simproviders')
  Future<ApiResponse<List<Map<String, dynamic>>>> getSimProviders();

  @GET('/admin/quicksimcards')
  Future<ApiResponse<List<Map<String, dynamic>>>> getQuickSimCards();

  @POST('/admin/simcards')
  Future<ApiResponse<void>> createSimCard(@Body() CreateAdminSimCardRequestDto body);

  @POST('/admin/devices')
  Future<ApiResponse<Map<String, dynamic>>> createDevice(@Body() CreateAdminDeviceRequestDto body);

  @POST('/admin/deviceandsim')
  Future<ApiResponse<void>> createDeviceAndSim(@Body() CreateAdminDeviceAndSimRequestDto body);

  @PATCH('/admin/devices/{deviceId}')
  Future<ApiResponse<void>> updateDevice(@Path('deviceId') String deviceId, @Body() UpdateAdminDeviceRequestDto body);
}
