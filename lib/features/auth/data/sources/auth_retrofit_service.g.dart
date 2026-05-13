// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_retrofit_service.dart';

class _AuthRetrofitService implements AuthRetrofitService {
  _AuthRetrofitService(this._dio, {this.baseUrl});

  final Dio _dio;
  final String? baseUrl;

  @override
  Future<ApiResponse<Map<String, dynamic>>> login(LoginRequest request) async {
    final response = await _dio.post<Object?>(
      AuthApiPaths.login,
      data: request.toJson(),
    );
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<void>> forgotPassword(ForgotPasswordRequestDto request) async {
    final response = await _dio.post<Object?>(
      AuthApiPaths.forgotPassword,
      data: request.toJson(),
    );
    return apiDecodeResponse<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> refreshToken(RefreshTokenRequestDto request) async {
    final response = await _dio.post<Object?>(
      AuthApiPaths.refreshToken,
      data: request.toJson(),
    );
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }
}
