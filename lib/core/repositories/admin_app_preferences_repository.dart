import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/admin_app_preferences.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class AdminAppPreferencesRepository {
  final ApiClient api;

  const AdminAppPreferencesRepository({required this.api});

  Future<Result<AdminAppPreferences>> getAdminAppPreferences({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/admin/config', cancelToken: cancelToken);

    return res.when(
      success: (data) => Result.ok(AdminAppPreferences(_extractMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updateAdminAppPreferences(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.patch(
      '/admin/config',
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

      final level1Candidates = [
        level1['result'],
        level1['items'],
        level1['config'],
        level1['settings'],
      ];

      for (final candidate in level1Candidates) {
        if (candidate is Map<String, dynamic>) return candidate;
        if (candidate is Map) {
          return Map<String, dynamic>.from(candidate.cast());
        }
      }

      return level1;
    }

    final level0Candidates = [
      level0['result'],
      level0['items'],
      level0['config'],
      level0['settings'],
    ];

    for (final candidate in level0Candidates) {
      if (candidate is Map<String, dynamic>) return candidate;
      if (candidate is Map) {
        return Map<String, dynamic>.from(candidate.cast());
      }
    }

    return level0;
  }
}
