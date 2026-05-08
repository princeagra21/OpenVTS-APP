import 'package:dio/dio.dart';
import 'package:open_vts/core/models/admin_profile.dart';
import 'package:open_vts/core/network/api_client.dart';
import 'package:open_vts/core/network/api_exception.dart';
import 'package:open_vts/core/network/result.dart';
import 'package:open_vts/core/network/api_paths.dart';

class AdminProfileRepository {
  final ApiClient api;

  const AdminProfileRepository({required this.api});

  Future<Result<AdminProfile>> getMyProfile({CancelToken? cancelToken}) async {
    final res = await api.get(AdminApiPaths.profile, cancelToken: cancelToken);
    return res.when(
      success: (data) => Result.ok(AdminProfile(_asMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<AdminProfile>> updateMyProfile(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.patch(
      AdminApiPaths.profile,
      data: payload,
      cancelToken: cancelToken,
    );
    return res.when(
      success: (data) => Result.ok(AdminProfile(_asMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updatePassword({
    required String currentPassword,
    required String newPassword,
    CancelToken? cancelToken,
  }) async {
    // Backend expects PATCH /admin/updatepassword
    // Body: { currentPassword: "...", newPassword: "..." }
    final current = currentPassword.trim();
    final next = newPassword.trim();
    if (current.isEmpty || next.isEmpty) {
      return Result.fail(
        const ApiException(message: 'currentPassword and newPassword required'),
      );
    }

    final body = <String, dynamic>{
      'currentPassword': current,
      'newPassword': next,
    };

    final res = await api.patch(
      AdminApiPaths.updatePassword,
      data: body,
      cancelToken: cancelToken,
    );
    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  // API reference documentation confirmed endpoints:
  // POST /admin/profile/verify/email/request
  // POST /admin/profile/verify/email/confirm  body: { "otp": "123456" }
  // POST /admin/profile/verify/whatsapp/request
  // POST /admin/profile/verify/whatsapp/confirm body: { "otp": "123456" }
  Future<Result<void>> sendEmailOtp({CancelToken? cancelToken}) async {
    final res = await api.post(
      AdminApiPaths.profileVerifyEmailRequest,
      // Some backend deployments reject POST with a null JSON body.
      data: const <String, dynamic>{},
      cancelToken: cancelToken,
    );
    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> verifyEmailOtp(
    String code, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.post(
      AdminApiPaths.profileVerifyEmailConfirm,
      data: {'otp': code.trim()},
      cancelToken: cancelToken,
    );
    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> sendPhoneOtp({CancelToken? cancelToken}) async {
    final res = await api.post(
      AdminApiPaths.profileVerifyWhatsappRequest,
      // Some backend deployments reject POST with a null JSON body.
      data: const <String, dynamic>{},
      cancelToken: cancelToken,
    );
    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> verifyPhoneOtp(
    String code, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.post(
      AdminApiPaths.profileVerifyWhatsappConfirm,
      data: {'otp': code.trim()},
      cancelToken: cancelToken,
    );
    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<Map<String, dynamic>>> updateCompanyDetails(
    String companyId,
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final id = companyId.trim();
    if (id.isEmpty) {
      return Result.fail(
        const ApiException(message: 'Company id is required'),
      );
    }
    final res = await api.patch(
      AdminApiPaths.companyDetails(id),
      data: payload,
      cancelToken: cancelToken,
    );
    return res.when(
      success: (data) => Result.ok(_asMap(data)),
      failure: (err) => Result.fail(err),
    );
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }
}
