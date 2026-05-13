import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:retrofit/retrofit.dart';

part 'user_vehicle_api_service.g.dart';

@RestApi()
abstract class UserVehicleApiService {
  factory UserVehicleApiService(Dio dio, {String? baseUrl}) = _UserVehicleApiService;

  @GET('/user/vehicles/{id}')
  Future<ApiResponse<Map<String, dynamic>>> getVehicleDetail(@Path('id') String id);
}
