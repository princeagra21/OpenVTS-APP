import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:open_vts/features/vehicles/data/models/vehicle_list_response.dart';
import 'package:retrofit/retrofit.dart';
import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/features/vehicles/data/models/vehicle_mutation_request_dto.dart';

part 'vehicle_retrofit_service.g.dart';

@RestApi()
abstract class VehicleApiService {
  factory VehicleApiService(Dio dio, {String? baseUrl}) = _VehicleApiService;

  @GET('/admin/vehicles')
  Future<ApiResponse<VehicleListResponse>> getVehicles({
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
    @Query('search') String? search,
    @Query('status') String? status,
  });

  @GET('/admin/vehicles/{id}')
  Future<ApiResponse<VehicleResponse>> getVehicleById(@Path('id') int id);

  @POST('/admin/vehicles')
  Future<ApiResponse<VehicleResponse>> createVehicle(@Body() VehicleMutationRequestDto request);

  @PUT('/admin/vehicles/{id}')
  Future<ApiResponse<VehicleResponse>> updateVehicle(@Path('id') int id, @Body() VehicleMutationRequestDto request);

  @DELETE('/admin/vehicles/{id}')
  Future<ApiResponse<void>> deleteVehicle(@Path('id') int id);
}
