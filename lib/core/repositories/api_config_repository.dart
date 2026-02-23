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
    if (data is! Map) {
      if (data is List && data.isNotEmpty) {
        final first = data.first;
        if (first is Map<String, dynamic>) return first;
        if (first is Map) return Map<String, dynamic>.from(first.cast());
      }
      return const <String, dynamic>{};
    }

    final level0 = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data.cast());

    final level1Raw = level0['data'];
    if (level1Raw is Map) {
      final level1 = Map<String, dynamic>.from(level1Raw.cast());
      final level2Raw = level1['data'];
      if (level2Raw is Map) {
        return Map<String, dynamic>.from(level2Raw.cast());
      }

      final candidates = [
        level1['result'],
        level1['items'],
        level1['settings'],
        level1['config'],
      ];
      for (final c in candidates) {
        if (c is Map<String, dynamic>) return c;
        if (c is Map) return Map<String, dynamic>.from(c.cast());
      }
      return level1;
    }

    final candidates = [
      level0['result'],
      level0['items'],
      level0['settings'],
      level0['config'],
    ];
    for (final c in candidates) {
      if (c is Map<String, dynamic>) return c;
      if (c is Map) return Map<String, dynamic>.from(c.cast());
    }

    return level0;
  }

  Result<void> unavailableTestApi() =>
      Result.fail(const ApiException(message: 'Test API not available yet'));
}
