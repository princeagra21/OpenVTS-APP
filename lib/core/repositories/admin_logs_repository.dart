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
    final requestedLimit = limit ?? 20;
    final activityLimit = _clamp(requestedLimit, min: 5, max: 50);
    final eventsLimit = _clamp(requestedLimit, min: 1, max: 200);

    final optionsQuery = <String, dynamic>{};

    final activityQuery = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      activityQuery['q'] = search.trim();
    }
    activityQuery['limit'] = activityLimit;
    if (from != null && from.trim().isNotEmpty) {
      activityQuery['from'] = from.trim();
    }
    if (to != null && to.trim().isNotEmpty) activityQuery['to'] = to.trim();
    if (page != null) activityQuery['cursorId'] = page;

    final eventsQuery = <String, dynamic>{};
    eventsQuery['limit'] = eventsLimit;
    final severity = _mapLevelToSeverity(level);
    if (severity != null) eventsQuery['severity'] = severity;

    final responses = await Future.wait([
      api.get(
        '/admin/logs/options',
        queryParameters: optionsQuery.isEmpty ? null : optionsQuery,
        cancelToken: cancelToken,
      ),
      api.get(
        '/admin/logs/activity',
        queryParameters: activityQuery.isEmpty ? null : activityQuery,
        cancelToken: cancelToken,
      ),
      api.get(
        '/admin/logs/events',
        queryParameters: eventsQuery.isEmpty ? null : eventsQuery,
        cancelToken: cancelToken,
      ),
    ]);

    final options = responses[0];
    final activityResult = responses[1];
    final events = responses[2];

    final anySuccess =
        options.isSuccess || activityResult.isSuccess || events.isSuccess;
    if (!anySuccess) {
      return Result.fail(
        activityResult.error ??
            events.error ??
            options.error ??
            'Failed to load logs',
      );
    }

    final merged = <AdminLogItem>[];
    if (activityResult.isSuccess) {
      merged.addAll(_parseLogs(activityResult.data));
    }
    if (events.isSuccess) {
      merged.addAll(_parseLogs(events.data));
    }
    if (options.isSuccess) {
      merged.addAll(
        _parseLogs(options.data).where(
          (item) =>
              item.time.isNotEmpty ||
              item.message.isNotEmpty ||
              item.type.isNotEmpty,
        ),
      );
    }

    return Result.ok(_dedupeAndSortByTime(merged));
  }

  List<AdminLogItem> _dedupeAndSortByTime(List<AdminLogItem> input) {
    if (input.isEmpty) return const <AdminLogItem>[];

    final seen = <String>{};
    final unique = <AdminLogItem>[];

    for (final item in input) {
      final key = item.id.isNotEmpty
          ? 'id:${item.id}'
          : 'key:${item.time}|${item.type}|${item.entity}|${item.message}';
      if (!seen.add(key)) continue;
      unique.add(item);
    }

    unique.sort((a, b) => _toEpochMs(b.time).compareTo(_toEpochMs(a.time)));
    return unique;
  }

  int _toEpochMs(String rawTime) {
    final raw = rawTime.trim();
    if (raw.isEmpty) return 0;

    final numeric = int.tryParse(raw);
    if (numeric != null) {
      if (numeric > 1000000000000) return numeric; // milliseconds
      if (numeric > 1000000000) return numeric * 1000; // seconds
    }

    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso.millisecondsSinceEpoch;

    final compactIso = DateTime.tryParse(raw.replaceAll(',', ''));
    if (compactIso != null) return compactIso.millisecondsSinceEpoch;

    final slash12h = RegExp(
      r'^(\d{1,2})/(\d{1,2})/(\d{4})(?:,\s*|\s+)?(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([AaPp][Mm])?$',
    );
    final m12 = slash12h.firstMatch(raw);
    if (m12 != null) {
      final day = int.tryParse(m12.group(1) ?? '');
      final month = int.tryParse(m12.group(2) ?? '');
      final year = int.tryParse(m12.group(3) ?? '');
      var hour = int.tryParse(m12.group(4) ?? '');
      final minute = int.tryParse(m12.group(5) ?? '') ?? 0;
      final second = int.tryParse(m12.group(6) ?? '') ?? 0;
      final ampm = (m12.group(7) ?? '').toUpperCase();
      if (ampm == 'PM' && hour != null && hour < 12) hour += 12;
      if (ampm == 'AM' && hour == 12) hour = 0;
      if (day != null && month != null && year != null && hour != null) {
        return DateTime(
          year,
          month,
          day,
          hour,
          minute,
          second,
        ).millisecondsSinceEpoch;
      }
    }

    return 0;
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

  int _clamp(int value, {required int min, required int max}) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
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
