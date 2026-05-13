import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:retrofit/retrofit.dart';
import 'package:open_vts/features/user/data/models/user_driver_dtos.dart';

part 'user_driver_api_service.g.dart';

@RestApi()
abstract class UserDriverApiService {
  factory UserDriverApiService(Dio dio, {String? baseUrl}) = _UserDriverApiService;

  @GET('/user/drivers')
  Future<ApiResponse<List<Map<String, dynamic>>>> getDrivers();

  @GET('/user/drivers/{id}')
  Future<ApiResponse<Map<String, dynamic>>> getDriverDetail(@Path('id') String id);

  @POST('/user/drivers')
  Future<ApiResponse<Map<String, dynamic>>> createDriver(@Body() UserDriverMutationDto body);

  @PATCH('/user/drivers/{id}')
  Future<ApiResponse<void>> updateDriver(@Path('id') String id, @Body() UserDriverMutationDto body);

  @DELETE('/user/drivers/{id}')
  Future<ApiResponse<void>> deleteDriver(@Path('id') String id, @Body() UserDriverMutationDto body);
}
