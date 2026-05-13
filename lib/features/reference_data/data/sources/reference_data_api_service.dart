import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:retrofit/retrofit.dart';

part 'reference_data_api_service.g.dart';

@RestApi()
abstract class ReferenceDataApiService {
  factory ReferenceDataApiService(Dio dio, {String? baseUrl}) = _ReferenceDataApiService;

  @GET('/countries')
  Future<ApiResponse<List<Map<String, dynamic>>>> getCountries();

  @GET('/states/{countryCode}')
  Future<ApiResponse<List<Map<String, dynamic>>>> getStates(@Path('countryCode') String countryCode);

  @GET('/cities/{countryCode}/{stateCode}')
  Future<ApiResponse<List<Map<String, dynamic>>>> getCities(
    @Path('countryCode') String countryCode,
    @Path('stateCode') String stateCode,
  );

  @GET('/mobileprefix')
  Future<ApiResponse<List<Map<String, dynamic>>>> getMobilePrefixes();

  @GET('/vehicletypes')
  Future<ApiResponse<List<Map<String, dynamic>>>> getVehicleTypes();

  @GET('/languages')
  Future<ApiResponse<List<Map<String, dynamic>>>> getLanguages();

  @GET('/dateformats')
  Future<ApiResponse<List<Map<String, dynamic>>>> getDateFormats();

  @GET('/timezones')
  Future<ApiResponse<List<Map<String, dynamic>>>> getTimezones();
}
