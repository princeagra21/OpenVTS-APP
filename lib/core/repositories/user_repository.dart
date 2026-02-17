import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/profile.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class UserRepository {
  final ApiClient api;

  UserRepository({required this.api});

  /// Protected call example (requires token): choose a lightweight endpoint from your API.
  ///
  /// This is intentionally flexible since backend response shapes vary.
  Future<Result<Profile>> getProfile({CancelToken? cancelToken}) async {
    // If your backend doesn't have `/user/profile`, adjust this to a known endpoint
    // from the Postman collection.
    final res = await api.get('/user/profile', cancelToken: cancelToken);

    return res.when(
      success: (data) => Result.ok(Profile(_coerceMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

  Map<String, dynamic> _coerceMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data.cast());
    return const <String, dynamic>{};
  }
}
