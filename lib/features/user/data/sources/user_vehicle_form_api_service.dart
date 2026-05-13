import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:retrofit/retrofit.dart';
import 'package:open_vts/features/user/data/models/user_vehicle_form_dtos.dart';

part 'user_vehicle_form_api_service.g.dart';

@RestApi()
abstract class UserVehicleFormApiService {
  factory UserVehicleFormApiService(Dio dio, {String? baseUrl}) = _UserVehicleFormApiService;

  @GET('/vehicletypes')
  Future<ApiResponse<List<Map<String, dynamic>>>> getVehicleTypes();

  @POST('/user/vehicles')
  Future<ApiResponse<void>> createVehicle(@Body() CreateUserVehicleRequestDto body);
}
