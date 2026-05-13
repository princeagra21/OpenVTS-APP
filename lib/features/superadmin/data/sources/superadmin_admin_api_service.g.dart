// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'superadmin_admin_api_service.dart';

class _SuperadminAdminApiService implements SuperadminAdminApiService {
  _SuperadminAdminApiService(this._dio, {this.baseUrl});

  final Dio _dio;
  final String? baseUrl;

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getAdmins({int? page, int? limit, String? status}) async {
    final query = <String, dynamic>{};
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;
    if (status != null && status.trim().isNotEmpty) query['status'] = status.trim();
    final response = await _dio.get<Object?>('/superadmin/adminlist', queryParameters: query.isEmpty ? null : query);
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getAdminDetail(String adminId) async {
    final response = await _dio.get<Object?>('/superadmin/admin/$adminId');
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> createAdmin(SuperadminAdminMutationDto body) async {
    final response = await _dio.post<Object?>('/superadmin/createadmin', data: body.toJson());
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> updateAdmin(String adminId, SuperadminAdminMutationDto body) async {
    final response = await _dio.post<Object?>('/superadmin/updateadmin/$adminId', data: body.toJson());
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<void>> activateAdmin(String adminId, SuperadminAdminStatusDto body) async {
    final response = await _dio.post<Object?>('/superadmin/activateadmin/$adminId', data: body.toPrimaryJson());
    return apiDecodeResponse<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<void>> updateAdminStatusFallback(SuperadminAdminMutationDto body) async {
    final response = await _dio.post<Object?>('/superadmin/adminstatusupdate', data: body.toJson());
    return apiDecodeResponse<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<void>> updateCompanyDetails(SuperadminCompanyMutationDto body) async {
    final response = await _dio.patch<Object?>('/superadmin/companydetails', data: body.toJson());
    return apiDecodeResponse<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<void>> updateCompanyConfig(String companyId, SuperadminCompanyMutationDto body) async {
    final response = await _dio.patch<Object?>('/superadmin/companyconfig/$companyId', data: body.toJson());
    return apiDecodeResponse<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> loginAsAdmin(String adminId) async {
    final response = await _dio.get<Object?>('/superadmin/adminlogin/$adminId');
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }
}
