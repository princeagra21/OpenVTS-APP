import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/admin_ticket_list_item.dart';
import 'package:fleet_stack/core/models/admin_ticket_message_item.dart';
import 'package:fleet_stack/core/models/user_ticket_details.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';
import 'package:fleet_stack/core/utils/file_picker_helper.dart';

class UserSupportRepository {
  final ApiClient api;

  const UserSupportRepository({required this.api});

  Future<Result<List<AdminTicketListItem>>> getTickets({
    int? rk,
    int? limit,
    CancelToken? cancelToken,
  }) async {
    final query = <String, dynamic>{};
    if (rk != null) query['rk'] = rk;
    if (limit != null) query['limit'] = limit;
    final res = await api.get(
      '/user/tickets',
      queryParameters: query.isEmpty ? null : query,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractTicketsList(data);
        final out = <AdminTicketListItem>[];
        if (list != null) {
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              out.add(AdminTicketListItem(item));
            } else if (item is Map) {
              out.add(
                AdminTicketListItem(Map<String, dynamic>.from(item.cast())),
              );
            }
          }
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  List? _extractTicketsList(Object? data) {
    if (data is! Map) return _extractList(data);

    final root = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data.cast());

    List? asList(Object? value) {
      if (value is List) return value;
      return null;
    }

    Map<String, dynamic> asMap(Object? value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value.cast());
      return const <String, dynamic>{};
    }

    final direct = asList(root['data']) ??
        asList(root['tickets']) ??
        asList(root['items']) ??
        asList(root['rows']) ??
        asList(root['results']);
    if (direct != null) return direct;

    final level1 = asMap(root['data']);
    final nested = asList(level1['data']) ??
        asList(level1['tickets']) ??
        asList(level1['items']) ??
        asList(level1['rows']) ??
        asList(level1['results']);
    if (nested != null) return nested;

    return _extractList(
      data,
      extraKeys: const ['tickets', 'items', 'rows', 'results'],
    );
  }

  Future<Result<UserTicketDetails>> getTicketDetails(
    String ticketId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/user/tickets/$ticketId',
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) => Result.ok(UserTicketDetails(_extractMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<AdminTicketMessageItem?>> sendTicketMessage(
    String ticketId,
    String message, {
    PickedFilePayload? attachment,
    CancelToken? cancelToken,
  }) async {
    Result<dynamic> res;

    if (attachment != null) {
      final form = FormData.fromMap({
        'message': message,
        'file': MultipartFile.fromBytes(
          attachment.bytes,
          filename: attachment.filename,
        ),
        'attachments': MultipartFile.fromBytes(
          attachment.bytes,
          filename: attachment.filename,
        ),
      });
      res = await api.post(
        '/user/tickets/$ticketId',
        data: form,
        cancelToken: cancelToken,
        options: Options(
          contentType: 'multipart/form-data',
          headers: const {
            'Accept': 'application/json',
          },
        ),
      );
    } else {
      res = await api.post(
        '/user/tickets/$ticketId',
        data: <String, dynamic>{'message': message},
        cancelToken: cancelToken,
      );
    }

    return res.when(
      success: (data) {
        final map = _extractMap(data);
        if (_messageLike(map)) {
          return Result.ok(AdminTicketMessageItem(map));
        }

        final messageId = map['messageId'] ?? map['id'];
        if (messageId != null) {
          return Result.ok(
            AdminTicketMessageItem(<String, dynamic>{
              'messageId': messageId,
              'message': message,
              'createdAt': DateTime.now().toIso8601String(),
              'senderName': 'You',
            }),
          );
        }

        return Result.ok(null);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> createTicket({
    required String title,
    required String category,
    required String priority,
    required String message,
    CancelToken? cancelToken,
  }) async {
    final res = await api.post(
      '/user/tickets',
      data: <String, dynamic>{
        'title': title,
        'category': category,
        'priority': priority,
        'message': message,
      },
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  bool _messageLike(Map<String, dynamic> map) {
    final keys = map.keys.map((e) => e.toString().toLowerCase()).toSet();
    return keys.contains('message') ||
        keys.contains('content') ||
        keys.contains('text') ||
        keys.contains('sender') ||
        keys.contains('sendername');
  }

  Map<String, dynamic> _extractMap(Object? data) {
    if (data is! Map) return const <String, dynamic>{};

    final level0 = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data.cast());
    final objectKeys = const ['ticket'];

    Map<String, dynamic>? fromNode(Map<String, dynamic> node) {
      for (final key in objectKeys) {
        final value = node[key];
        if (value is Map<String, dynamic>) return value;
        if (value is Map) return Map<String, dynamic>.from(value.cast());
      }
      return null;
    }

    final directLevel0 = fromNode(level0);
    if (directLevel0 != null) return directLevel0;

    final level1Raw = level0['data'] ?? level0['result'] ?? level0['item'];
    if (level1Raw is Map) {
      final level1 = Map<String, dynamic>.from(level1Raw.cast());
      final directLevel1 = fromNode(level1);
      if (directLevel1 != null) return directLevel1;

      final level2Raw = level1['data'] ?? level1['result'] ?? level1['item'];
      if (level2Raw is Map) {
        final level2 = Map<String, dynamic>.from(level2Raw.cast());
        final directLevel2 = fromNode(level2);
        if (directLevel2 != null) return directLevel2;
        return level2;
      }

      return level1;
    }

    return level0;
  }

  List? _extractList(
    Object? data, {
    List<String> extraKeys = const <String>[],
  }) {
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
