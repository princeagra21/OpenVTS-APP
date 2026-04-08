import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/admin_calendar_event_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class AdminCalendarRepository {
  final ApiClient api;

  const AdminCalendarRepository({required this.api});

  Future<Result<List<AdminCalendarEventItem>>> getCalendarEvents({
    required String from,
    required String to,
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/admin/calendar/events',
      queryParameters: <String, dynamic>{'from': from, 'to': to},
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final out = <AdminCalendarEventItem>[];

        final list = _extractList(
          data,
          extraKeys: const ['events', 'calendarEvents', 'items', 'rows'],
        );

        if (list != null) {
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              out.add(AdminCalendarEventItem(_normalizeEventMap(item)));
            } else if (item is Map) {
              out.add(
                AdminCalendarEventItem(
                  _normalizeEventMap(
                    Map<String, dynamic>.from(item.cast()),
                  ),
                ),
              );
            }
          }
          return Result.ok(out);
        }

        // Also tolerate map-by-date shape: {"2025-06-15": [ ...events ]}.
        final root = _asMap(data);
        root.forEach((key, value) {
          if (value is List) {
            for (final event in value) {
              if (event is Map<String, dynamic>) {
                out.add(
                  AdminCalendarEventItem(<String, dynamic>{
                    'date': key,
                    ..._normalizeEventMap(event),
                  }),
                );
              } else if (event is Map) {
                out.add(
                  AdminCalendarEventItem(<String, dynamic>{
                    'date': key,
                    ..._normalizeEventMap(
                      Map<String, dynamic>.from(event.cast()),
                    ),
                  }),
                );
              }
            }
          }
        });

        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<Map<String, dynamic>>> getCalendarUserDetails(
    String userId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/admin/calendar/user/$userId',
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) => Result.ok(_asMap(data)),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<Map<String, dynamic>>> getCalendarDayDetails({
    required String date,
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/admin/calendar/day',
      queryParameters: {'date': date},
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) => Result.ok(_asMap(data)),
      failure: (err) => Result.fail(err),
    );
  }

  List? _extractList(Object? data, {List<String> extraKeys = const []}) {
    if (data is List) return data;
    if (data is! Map) return null;

    final keys = <String>['data', 'items', 'result', 'results', ...extraKeys];

    List? walk(Object? node, int depth) {
      if (depth > 6) return null;
      if (node is List) return node;
      if (node is! Map) return null;

      final map = _asMap(node);

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

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }

  Map<String, dynamic> _normalizeEventMap(Map<String, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    final type = map['type']?.toString() ?? '';
    final count = map['count'];
    final hasTitle = (map['title'] ?? map['name'] ?? map['label']) != null;
    if (count != null && !hasTitle) {
      final label = type.isNotEmpty ? type.replaceAll('_', ' ') : 'Events';
      map['title'] = '$label · $count';
      map['description'] = 'Count: $count';
    }
    return map;
  }
}
