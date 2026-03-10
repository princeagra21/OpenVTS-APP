import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/admin_profile.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class AdminProfileRepository {
  final ApiClient api;

  const AdminProfileRepository({required this.api});

  Future<Result<AdminProfile>> getMyProfile({CancelToken? cancelToken}) async {
    final res = await api.get('/admin/profile', cancelToken: cancelToken);
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
      '/admin/profile',
      data: payload,
      cancelToken: cancelToken,
    );
    return res.when(
      success: (data) => Result.ok(AdminProfile(_asMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updatePassword({
    String? currentPassword,
    required String newPassword,
    String? confirmPassword,
    CancelToken? cancelToken,
  }) async {
    final body = <String, dynamic>{
      // Postman-confirmed keys:
      // currentPassword, newPassword
      // Keep confirmPassword optional for tolerant backend variants.
      if (currentPassword != null && currentPassword.trim().isNotEmpty)
        'currentPassword': currentPassword.trim(),
      'newPassword': newPassword.trim(),
      if (confirmPassword != null && confirmPassword.trim().isNotEmpty)
        'confirmPassword': confirmPassword.trim(),
    };

    final res = await api.post(
      '/admin/updatepassword',
      data: body,
      cancelToken: cancelToken,
    );
    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  // FleetStack-API-Reference.md confirmed endpoints:
  // POST /admin/profile/verify/email/request
  // POST /admin/profile/verify/email/confirm  body: { "otp": "123456" }
  // POST /admin/profile/verify/whatsapp/request
  // POST /admin/profile/verify/whatsapp/confirm body: { "otp": "123456" }
  Future<Result<void>> sendEmailOtp({CancelToken? cancelToken}) async {
    final res = await api.post(
      '/admin/profile/verify/email/request',
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
      '/admin/profile/verify/email/confirm',
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
      '/admin/profile/verify/whatsapp/request',
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
      '/admin/profile/verify/whatsapp/confirm',
      data: {'otp': code.trim()},
      cancelToken: cancelToken,
    );
    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }
}
