// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_account_api_service.dart';

class _AdminAccountApiService implements AdminAccountApiService {
  _AdminAccountApiService(this._dio, {this.baseUrl});

  final Dio _dio;
  final String? baseUrl;

  ApiResponse<T> decode<T>(Object? data, T Function(Object? json) fromJsonT) {
    if (data is Map<String, dynamic>) return ApiResponse<T>.fromJson(data, fromJsonT);
    if (data is Map) return ApiResponse<T>.fromJson(Map<String, dynamic>.from(data.cast()), fromJsonT);
    return ApiResponse<T>(
      status: '',
      timestamp: null,
      data: ApiData<T>(action: false, message: 'Invalid API response', data: null),
    );
  }

  Map<String, dynamic> mapValue(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getUsers({Map<String, Object?>? query}) async {
    final response = await _dio.get<Object?>('/admin/users', queryParameters: query);
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getUserDetails(String userId) async {
    final response = await _dio.get<Object?>('/admin/users/$userId');
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> loginAsUser(String userId) async {
    final response = await _dio.get<Object?>('/admin/userlogin/$userId');
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<void>> updateUserStatus(String userId, UpdateAdminUserStatusRequestDto body) async {
    final response = await _dio.patch<Object?>('/admin/users/$userId', data: body.toJson());
    return decode<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getUserLinkedVehicles(String userId) async {
    final response = await _dio.get<Object?>('/admin/linkvehicles/$userId');
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getUserLinkedVehiclesByQuery({required String userId}) async {
    final response = await _dio.get<Object?>('/admin/linkvehicles', queryParameters: <String, Object?>{'userId': userId});
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getUnlinkedVehicles({Map<String, Object?>? query}) async {
    final response = await _dio.get<Object?>('/admin/unlinkvehicles', queryParameters: query);
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getUnlinkedVehiclesByUser(String userId) async {
    final response = await _dio.get<Object?>('/admin/unlinkvehicles/$userId');
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<void>> assignVehicleToUser(String vehicleId, AdminAssignVehicleRequestDto body) async {
    final response = await _dio.post<Object?>('/admin/linkusers/$vehicleId', data: body.toJson());
    return decode<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getUserLinkedDrivers(String userId) async {
    final response = await _dio.get<Object?>('/admin/users/unlinkeddrivers/$userId');
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getUserDocuments(String userId) async {
    final response = await _dio.get<Object?>('/admin/documents/$userId');
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getDocumentTypes() async {
    final response = await _dio.get<Object?>('/documenttypes/USER');
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<void>> uploadDocument(FormData form) async {
    final response = await _dio.post<Object?>('/admin/uploaddoc', data: form);
    return decode<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<void>> updateDocument(String documentId, FormData form) async {
    final response = await _dio.patch<Object?>('/admin/uploaddoc/$documentId', data: form);
    return decode<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<void>> deleteDocumentFile(String documentId) async {
    final response = await _dio.delete<Object?>('/admin/uploaddoc/$documentId');
    return decode<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getUserTickets({Map<String, Object?>? query}) async {
    final response = await _dio.get<Object?>('/admin/tickets', queryParameters: query);
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getUserActivityLogs(String userId, {Map<String, Object?>? query}) async {
    final response = await _dio.get<Object?>('/admin/users/$userId/activitylogs', queryParameters: query);
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getUserPayments({Map<String, Object?>? query}) async {
    final response = await _dio.get<Object?>('/admin/payments', queryParameters: query);
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<void>> updateUserPassword(String userId, UpdateAdminUserPasswordRequestDto body) async {
    final response = await _dio.post<Object?>('/admin/updateuserpassword/$userId', data: body.toJson());
    return decode<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getMyProfile() async {
    final response = await _dio.get<Object?>('/admin/profile');
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> updateMyProfile(AdminProfileUpdateRequestDto body) async {
    final response = await _dio.patch<Object?>('/admin/profile', data: body.toJson());
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<void>> updatePassword(UpdateAdminPasswordRequestDto body) async {
    final response = await _dio.patch<Object?>('/admin/updatepassword', data: body.toJson());
    return decode<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<void>> sendEmailOtp(AdminOtpRequestDto body) async {
    final response = await _dio.post<Object?>('/admin/profile/verify/email/request', data: body.toJson());
    return decode<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<void>> verifyEmailOtp(AdminOtpRequestDto body) async {
    final response = await _dio.post<Object?>('/admin/profile/verify/email/confirm', data: body.toJson());
    return decode<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<void>> sendPhoneOtp(AdminOtpRequestDto body) async {
    final response = await _dio.post<Object?>('/admin/profile/verify/whatsapp/request', data: body.toJson());
    return decode<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<void>> verifyPhoneOtp(AdminOtpRequestDto body) async {
    final response = await _dio.post<Object?>('/admin/profile/verify/whatsapp/confirm', data: body.toJson());
    return decode<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> updateCompanyDetails(String companyId, AdminCompanyUpdateRequestDto body) async {
    final response = await _dio.patch<Object?>('/admin/companydetails/$companyId', data: body.toJson());
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> uploadAdminFile(FormData form) async {
    final response = await _dio.post<Object?>('/admin/upload', data: form);
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getLinkedVehicles(String userId, {Map<String, Object?>? query}) async {
    final response = await _dio.get<Object?>('/admin/linkvehicles/$userId', queryParameters: query);
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<void>> renewVehicles(AdminRenewVehiclesRequestDto body) async {
    final response = await _dio.post<Object?>('/admin/payments/renew', data: body.toJson());
    return decode<void>(response.data, (_) {});
  }
}
