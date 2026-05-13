import 'package:open_vts/core/api/api_envelope.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:open_vts/features/admin/domain/entities/admin_calendar_event_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_linked_vehicle.dart';
import 'package:open_vts/features/admin/domain/entities/admin_log_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_notification_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_transaction_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_transactions_summary.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_recipient.dart';
import 'package:open_vts/features/admin/domain/entities/pricing_plan.dart';

class AdminOperationsMapper {
  const AdminOperationsMapper();

  List<AdminCalendarEventItem> calendarEvents(ApiResponse<Map<String, Object?>> response) {
    final out = <AdminCalendarEventItem>[];
    final list = ApiEnvelope.mapList(
      response.payload,
      listKeys: const ['events', 'calendarEvents', 'items', 'rows', 'data', 'result', 'results'],
    );
    for (final raw in list) {
      out.add(AdminCalendarEventItem(_normalizeEventMap(raw)));
    }

    if (out.isNotEmpty) return out;

    final root = ApiEnvelope.asMap(response.payload);
    root.forEach((key, value) {
      if (value is List) {
        for (final item in value) {
          final map = ApiEnvelope.asMap(item);
          if (map.isNotEmpty) {
            out.add(AdminCalendarEventItem(<String, Object?>{'date': key, ..._normalizeEventMap(map)}));
          }
        }
      }
    });
    return out;
  }

  List<AdminCalendarEventItem> calendarDayEvents(ApiResponse<Map<String, Object?>> response, {required String date}) {
    final events = calendarEvents(response);
    if (events.isNotEmpty) return events;
    final root = ApiEnvelope.asMap(response.payload);
    if (root.isEmpty) return const <AdminCalendarEventItem>[];
    return <AdminCalendarEventItem>[AdminCalendarEventItem(<String, Object?>{'date': date, ...root})];
  }

  List<AdminLogItem> logsFromResponses(Iterable<ApiResponse<Map<String, Object?>>> responses) {
    final merged = <AdminLogItem>[];
    for (final response in responses) {
      merged.addAll(_logs(response));
    }
    return _dedupeAndSortByTime(merged);
  }

  List<AdminNotificationItem> notifications(ApiResponse<Map<String, Object?>> response) {
    return ApiEnvelope
        .mapList(response.payload, listKeys: const ['notifications', 'notification', 'rows', 'items', 'data', 'result', 'results'])
        .map(AdminNotificationItem.new)
        .toList();
  }

  List<AdminUserRecipient> recipients(ApiResponse<Map<String, Object?>> response) {
    return ApiEnvelope
        .mapList(response.payload, listKeys: const ['users', 'userslist', 'items', 'rows', 'data', 'result', 'results'])
        .map(AdminUserRecipient.new)
        .toList();
  }

  List<AdminTransactionItem> payments(ApiResponse<Map<String, Object?>> response) {
    return ApiEnvelope
        .mapList(response.payload, listKeys: const ['payments', 'transactions', 'items', 'data', 'rows', 'result', 'results'])
        .map(AdminTransactionItem.fromRaw)
        .toList();
  }

  List<PricingPlan> pricingPlans(ApiResponse<Map<String, Object?>> response) {
    return ApiEnvelope
        .mapList(response.payload, listKeys: const ['plans', 'pricingPlans', 'items', 'rows', 'data', 'result', 'results'])
        .map(PricingPlan.fromRaw)
        .toList();
  }

  List<AdminTransactionItem> transactions(ApiResponse<Map<String, Object?>> response) {
    return ApiEnvelope
        .mapList(response.payload, listKeys: const ['transactions', 'items', 'results', 'rows', 'data', 'result'])
        .map(AdminTransactionItem.fromRaw)
        .toList();
  }

  AdminTransactionsSummary transactionsSummary(ApiResponse<Map<String, Object?>> response) {
    final root = ApiEnvelope.asMap(response.payload);
    for (final key in const ['analytics', 'summary', 'stats', 'totals', 'data', 'result']) {
      final nested = ApiEnvelope.asMap(root[key]);
      if (nested.isNotEmpty) return AdminTransactionsSummary.fromRaw(nested);
    }
    return AdminTransactionsSummary.fromRaw(root);
  }

  List<AdminLinkedVehicle> linkedVehicles(ApiResponse<Map<String, Object?>> response) {
    return ApiEnvelope
        .mapList(response.payload, listKeys: const ['vehicles', 'linkedVehicles', 'items', 'rows', 'data', 'result', 'results'])
        .map(AdminLinkedVehicle.fromJson)
        .toList();
  }

  List<AdminLogItem> _logs(ApiResponse<Map<String, Object?>> response) {
    return ApiEnvelope
        .mapList(response.payload, listKeys: const ['logs', 'events', 'activity', 'items', 'rows', 'data', 'result', 'results'])
        .map(AdminLogItem.new)
        .toList();
  }

  Map<String, Object?> _normalizeEventMap(Map<String, Object?> raw) {
    final map = Map<String, Object?>.from(raw);
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

  List<AdminLogItem> _dedupeAndSortByTime(List<AdminLogItem> input) {
    if (input.isEmpty) return const <AdminLogItem>[];
    final seen = <String>{};
    final unique = <AdminLogItem>[];
    for (final item in input) {
      final key = item.id.isNotEmpty ? 'id:${item.id}' : 'key:${item.time}|${item.type}|${item.entity}|${item.message}';
      if (seen.add(key)) unique.add(item);
    }
    unique.sort((a, b) => _toEpochMs(b.time).compareTo(_toEpochMs(a.time)));
    return unique;
  }

  int _toEpochMs(String rawTime) {
    final raw = rawTime.trim();
    if (raw.isEmpty) return 0;
    final numeric = int.tryParse(raw);
    if (numeric != null) {
      if (numeric > 1000000000000) return numeric;
      if (numeric > 1000000000) return numeric * 1000;
    }
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso.millisecondsSinceEpoch;
    return 0;
  }
}
