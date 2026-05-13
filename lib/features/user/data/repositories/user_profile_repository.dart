import 'package:open_vts/core/utils/request_control.dart';
import 'package:open_vts/shared/models/admin_profile.dart';
import 'package:open_vts/core/api/api_result.dart';
import 'package:open_vts/core/api/api_paths.dart';
import 'package:open_vts/features/user/data/sources/user_typed_api_transport.dart';

/// Infrastructure is injected by AppContainer.
/// Do not instantiate transport client, AppConfig, or TokenStorage inside this repository.
class UserProfileRepository {
  final UserTypedApiTransport api;

  UserProfileRepository({required Object api}) : api = api is UserTypedApiTransport ? api : UserTypedApiTransport.fromDio((api as dynamic).dio as Dio);

  Future<Result<AdminProfile>> getMyProfile({CancelToken? cancelToken}) async {
    final res = await api.get(
      UserApiPaths.profile,
      cancelToken: cancelToken,
    );
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
      UserApiPaths.profile,
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
      if (currentPassword != null && currentPassword.trim().isNotEmpty)
        'currentPassword': currentPassword.trim(),
      'newPassword': newPassword.trim(),
      if (confirmPassword != null && confirmPassword.trim().isNotEmpty)
        'confirmPassword': confirmPassword.trim(),
    };

    final res = await api.patch(
      UserApiPaths.updatePassword,
      data: body,
      cancelToken: cancelToken,
    );
    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> sendEmailOtp({CancelToken? cancelToken}) async {
    final res = await api.post(
      UserApiPaths.profileVerifyEmailRequest,
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
      UserApiPaths.profileVerifyEmailConfirm,
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
      UserApiPaths.profileVerifyWhatsappRequest,
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
      UserApiPaths.profileVerifyWhatsappConfirm,
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
