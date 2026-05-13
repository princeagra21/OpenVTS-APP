import 'package:open_vts/core/utils/request_control.dart';
import 'package:open_vts/features/user/domain/entities/user_fleet_status_summary.dart';
import 'package:open_vts/features/user/domain/entities/user_recent_alert_item.dart';
import 'package:open_vts/features/user/domain/entities/user_top_asset_item.dart';
import 'package:open_vts/features/user/domain/entities/user_usage_last_7_days.dart';
import 'package:open_vts/core/api/api_result.dart';
import 'package:open_vts/core/api/api_paths.dart';
import 'package:open_vts/core/api/legacy_api_transport.dart';

class UserHomeRepository {
  final LegacyApiTransport api;

  const UserHomeRepository({required this.api});

  Future<Result<UserFleetStatusSummary>> getFleetStatus({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      UserApiPaths.dashboardFleetStatus,
      queryParameters: <String, dynamic>{
        'rk': DateTime.now().millisecondsSinceEpoch,
      },
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
      UserApiPaths.dashboardUsageLast7Days,
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
      UserApiPaths.dashboardRecentAlerts,
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
      UserApiPaths.dashboardTopPerformingAssets,
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
