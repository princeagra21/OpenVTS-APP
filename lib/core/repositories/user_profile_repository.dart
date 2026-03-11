import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/admin_profile.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class UserProfileRepository {
  final ApiClient api;

  const UserProfileRepository({required this.api});

  Future<Result<AdminProfile>> getMyProfile({CancelToken? cancelToken}) async {
    final res = await api.get('/user/profile', cancelToken: cancelToken);
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
      '/user/profile',
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
      '/user/updatepassword',
      data: body,
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
