import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:open_vts/core/api/api_paths.dart';
import 'package:open_vts/features/auth/data/models/login_request.dart';
import 'package:retrofit/retrofit.dart';
import 'package:open_vts/features/auth/data/models/auth_request_dtos.dart';

part 'auth_retrofit_service.g.dart';

@RestApi()
abstract class AuthRetrofitService {
  factory AuthRetrofitService(Dio dio, {String? baseUrl}) = _AuthRetrofitService;

  @POST(AuthApiPaths.login)
  Future<ApiResponse<Map<String, dynamic>>> login(@Body() LoginRequest request);

  @POST(AuthApiPaths.forgotPassword)
  Future<ApiResponse<void>> forgotPassword(@Body() ForgotPasswordRequestDto request);

  @POST(AuthApiPaths.refreshToken)
  Future<ApiResponse<Map<String, dynamic>>> refreshToken(@Body() RefreshTokenRequestDto request);
}
