import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:open_vts/features/settings/data/models/settings_response.dart';
import 'package:retrofit/retrofit.dart';
import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/features/settings/data/models/settings_update_request_dto.dart';

part 'settings_retrofit_service.g.dart';

@RestApi()
abstract class SettingsApiService {
  factory SettingsApiService(Dio dio, {String? baseUrl}) = _SettingsApiService;

  @GET('/settings')
  Future<ApiResponse<SettingsResponse>> getSettings();

  @PUT('/settings')
  Future<ApiResponse<SettingsResponse>> updateSettings(@Body() SettingsUpdateRequestDto request);
}
