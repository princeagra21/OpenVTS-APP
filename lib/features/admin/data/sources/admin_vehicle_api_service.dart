import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:retrofit/retrofit.dart';
import 'package:open_vts/features/admin/data/models/admin_vehicle_dtos.dart';

part 'admin_vehicle_api_service.g.dart';

@RestApi()
abstract class AdminVehicleApiService {
  factory AdminVehicleApiService(Dio dio, {String? baseUrl}) = _AdminVehicleApiService;

  @GET('/admin/vehicles/{vehicleId}')
  Future<ApiResponse<Map<String, dynamic>>> getVehicleDetail(@Path('vehicleId') String vehicleId);

  @GET('/admin/linkusers/{vehicleId}')
  Future<ApiResponse<List<Map<String, dynamic>>>> getLinkedUsers(@Path('vehicleId') String vehicleId);

  @GET('/admin/documents/vehicle/{vehicleId}')
  Future<ApiResponse<List<Map<String, dynamic>>>> getVehicleDocuments(@Path('vehicleId') String vehicleId);

  @GET('/admin/vehicles/{vehicleId}/config')
  Future<ApiResponse<Map<String, dynamic>>> getVehicleConfig(@Path('vehicleId') String vehicleId);

  @PATCH('/admin/vehicles/{vehicleId}/config')
  Future<ApiResponse<void>> updateVehicleConfig(@Path('vehicleId') String vehicleId, @Body() AdminVehicleConfigUpdateRequestDto body);

  @GET('/admin/vehicles/by-imei/{imei}/logs')
  Future<ApiResponse<List<Map<String, dynamic>>>> getVehicleLogsByImei(
    @Path('imei') String imei, {
    @Queries() Map<String, Object?>? query,
  });

  @PATCH('/admin/vehicles/{vehicleId}')
  Future<ApiResponse<void>> updateVehicle(@Path('vehicleId') String vehicleId, @Body() UpdateAdminVehicleStatusRequestDto body);

  @DELETE('/admin/vehicles/{vehicleId}')
  Future<ApiResponse<void>> deleteVehicle(@Path('vehicleId') String vehicleId);

  @POST('/admin/vehicles/{vehicleId}/driver')
  Future<ApiResponse<void>> assignDriver(@Path('vehicleId') String vehicleId, @Body() AdminVehicleDriverAssignmentRequestDto body);

  @DELETE('/admin/vehicles/{vehicleId}/driver')
  Future<ApiResponse<void>> unassignDriver(@Path('vehicleId') String vehicleId);
}
