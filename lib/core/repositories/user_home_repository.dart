import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/user_fleet_status_summary.dart';
import 'package:fleet_stack/core/models/user_recent_alert_item.dart';
import 'package:fleet_stack/core/models/user_top_asset_item.dart';
import 'package:fleet_stack/core/models/user_usage_last_7_days.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class UserHomeRepository {
  final ApiClient api;

  const UserHomeRepository({required this.api});

  Future<Result<UserFleetStatusSummary>> getFleetStatus({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/user/dashboard/fleet-status',
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) => Result.ok(UserFleetStatusSummary(_asMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<UserUsageLast7Days>> getUsageLast7Days({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/user/dashboard/usage-last-7-days',
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) => Result.ok(UserUsageLast7Days(_asMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<UserRecentAlertItem>>> getRecentAlerts({
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/user/dashboard/recent-alerts',
      queryParameters: {'limit': limit},
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final payload = _extractPayload(data);
        final items = _asList(
          payload['items'],
        ).map(UserRecentAlertItem.new).toList();
        return Result.ok(items);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<UserTopAssetItem>>> getTopPerformingAssets({
    int limit = 10,
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/user/dashboard/top-performing-assets',
      queryParameters: {'limit': limit},
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final payload = _extractPayload(data);
        final items = _asList(
          payload['items'],
        ).map(UserTopAssetItem.new).toList();
        return Result.ok(items);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Map<String, dynamic> _extractPayload(Object? data) {
    final root = _asMap(data);
    final level1 = _asMap(root['data']);
    final level2 = _asMap(level1['data']);
    return level2.isNotEmpty ? level2 : (level1.isNotEmpty ? level1 : root);
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asList(Object? value) {
    if (value is List<Map<String, dynamic>>) return value;
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item.cast()))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }
}
