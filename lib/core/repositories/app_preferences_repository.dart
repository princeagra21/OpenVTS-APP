import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/app_preferences.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class AppPreferencesRepository {
  final ApiClient api;

  const AppPreferencesRepository({required this.api});

  // Postman-confirmed endpoints for this screen:
  // - GET /superadmin/softwareconfig
  // - PATCH /superadmin/softwareconfig

  Future<Result<AppPreferences>> getAppPreferences({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/superadmin/softwareconfig',
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) => Result.ok(AppPreferences(_extractMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updateAppPreferences(
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
        data['config'],
        data['settings'],
      ];
      for (final c in candidates) {
        if (c is Map<String, dynamic>) return c;
        if (c is Map) return Map<String, dynamic>.from(c.cast());
      }
      return data;
    }

    if (data is Map) return Map<String, dynamic>.from(data.cast());

    if (data is List && data.isNotEmpty) {
      final first = data.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first.cast());
    }

    return const <String, dynamic>{};
  }
}
