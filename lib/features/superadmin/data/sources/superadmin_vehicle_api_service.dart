import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:retrofit/retrofit.dart';
import 'package:open_vts/features/superadmin/data/models/superadmin_vehicle_dtos.dart';

part 'superadmin_vehicle_api_service.g.dart';

@RestApi()
abstract class SuperadminVehicleApiService {
  factory SuperadminVehicleApiService(Dio dio, {String? baseUrl}) = _SuperadminVehicleApiService;

  @GET('/superadmin/adminvehicles/{adminId}')
  Future<ApiResponse<List<Map<String, dynamic>>>> getAdminVehicles(@Path('adminId') String adminId);

  @GET('/superadmin/vehicles')
  Future<ApiResponse<List<Map<String, dynamic>>>> getVehicles({@Query('page') int? page, @Query('limit') int? limit});

  @GET('/superadmin/vehicles/{vehicleId}')
  Future<ApiResponse<Map<String, dynamic>>> getVehicleDetail(@Path('vehicleId') String vehicleId);

  @GET('/superadmin/vehicles/by-imei/{imei}/details')
  Future<ApiResponse<Map<String, dynamic>>> getVehicleByImeiDetail(@Path('imei') String imei);

  @GET('/superadmin/commandtypes')
  Future<ApiResponse<List<Map<String, dynamic>>>> getCommandOptions();

  @POST('/superadmin/customcommands')
  Future<ApiResponse<Map<String, dynamic>>> sendCommand(@Body() SuperadminSendCommandRequestDto body);

  @GET('/superadmin/customcommands')
  Future<ApiResponse<List<Map<String, dynamic>>>> getRecentCommands();
}
