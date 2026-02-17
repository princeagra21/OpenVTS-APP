import 'package:dio/dio.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class ApiConfigRepository {
  final ApiClient api;

  const ApiConfigRepository({required this.api});

  // Postman-confirmed:
  // - GET /superadmin/softwareconfig
  // - PATCH /superadmin/softwareconfig
  // No dedicated test endpoints found for firebase/geocoding/sso/openai.

  Future<Result<Map<String, dynamic>>> getSoftwareConfig({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/superadmin/softwareconfig',
      cancelToken: cancelToken,
    );
    return res.when(
      success: (data) => Result.ok(_extractMap(data)),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updateSoftwareConfig(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.patch(
      '/superadmin/softwareconfig',
      data: payload,
      cancelToken: cancelToken,
    );
    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Map<String, dynamic> _extractMap(Object? data) {
    if (data is Map<String, dynamic>) {
      final candidates = [
        data['data'],
        data['result'],
        data['items'],
        data['settings'],
        data['config'],
      ];
      for (final c in candidates) {
        if (c is Map<String, dynamic>) return c;
        if (c is Map) return Map<String, dynamic>.from(c.cast());
      }
      return data;
    }
    if (data is List && data.isNotEmpty) {
      final first = data.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first.cast());
    }
    if (data is Map) return Map<String, dynamic>.from(data.cast());
    return const <String, dynamic>{};
  }

  Result<void> unavailableTestApi() =>
      Result.fail(const ApiException(message: 'Test API not available yet'));
}
