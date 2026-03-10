import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/admin_log_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class AdminLogsRepository {
  final ApiClient api;

  const AdminLogsRepository({required this.api});

  Future<Result<List<AdminLogItem>>> getLogs({
    String? search,
    String? level,
    int? page,
    int? limit,
    String? from,
    String? to,
    CancelToken? cancelToken,
  }) async {
    final primaryQuery = <String, dynamic>{};
    if (limit != null) primaryQuery['limit'] = limit;

    final severity = _mapLevelToSeverity(level);
    if (severity != null) primaryQuery['severity'] = severity;

    final primary = await api.get(
      '/admin/logs/events',
      queryParameters: primaryQuery.isEmpty ? null : primaryQuery,
      cancelToken: cancelToken,
    );

    if (primary.isSuccess) {
      final parsed = _parseLogs(primary.data);
      return Result.ok(parsed);
    }

    final fallbackQuery = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      fallbackQuery['q'] = search.trim();
    }
    if (limit != null) fallbackQuery['limit'] = limit;
    if (from != null && from.trim().isNotEmpty) {
      fallbackQuery['from'] = from.trim();
    }
    if (to != null && to.trim().isNotEmpty) fallbackQuery['to'] = to.trim();
    if (page != null) fallbackQuery['cursorId'] = page;

    final activity = await api.get(
      '/admin/logs/activity',
      queryParameters: fallbackQuery.isEmpty ? null : fallbackQuery,
      cancelToken: cancelToken,
    );

    if (activity.isSuccess) {
      final parsed = _parseLogs(activity.data);
      return Result.ok(parsed);
    }

    return Result.fail(
      activity.error ?? primary.error ?? 'Failed to load logs',
    );
  }

  List<AdminLogItem> _parseLogs(Object? data) {
    final list = _extractList(
      data,
      extraKeys: const ['logs', 'events', 'activity', 'items', 'rows'],
    );
    final out = <AdminLogItem>[];
    if (list == null) return out;

    for (final item in list) {
      if (item is Map<String, dynamic>) {
        out.add(AdminLogItem(item));
      } else if (item is Map) {
        out.add(AdminLogItem(Map<String, dynamic>.from(item.cast())));
      }
    }
    return out;
  }

  String? _mapLevelToSeverity(String? level) {
    final normalized = (level ?? '').trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'all') return null;
    if (normalized == 'info') return 'INFO';
    if (normalized == 'warning' || normalized == 'warn') return 'WARNING';
    if (normalized == 'error' || normalized == 'critical') return 'CRITICAL';
    return null;
  }

  List? _extractList(Object? data, {List<String> extraKeys = const []}) {
    if (data is List) return data;
    if (data is! Map) return null;

    final keys = <String>['data', 'items', 'result', 'results', ...extraKeys];

    List? walk(Object? node, int depth) {
      if (depth > 6) return null;
      if (node is List) return node;
      if (node is! Map) return null;

      final map = node is Map<String, dynamic>
          ? node
          : Map<String, dynamic>.from(node.cast());

      for (final key in keys) {
        final value = map[key];
        if (value is List) return value;
      }

      for (final value in map.values) {
        if (value is List || value is Map) {
          final found = walk(value, depth + 1);
          if (found != null) return found;
        }
      }

      return null;
    }

    return walk(data, 0);
  }
}
