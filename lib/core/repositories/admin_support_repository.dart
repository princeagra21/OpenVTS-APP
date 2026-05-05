import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/admin_ticket_list_item.dart';
import 'package:fleet_stack/core/models/admin_ticket_message_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';
import 'package:fleet_stack/core/utils/file_picker_helper.dart';

class AdminSupportRepository {
  final ApiClient api;

  const AdminSupportRepository({required this.api});

  Future<Result<List<AdminTicketListItem>>> getTickets({
    String? status,
    String? search,
    int? page,
    int? limit,
    int? rk,
    CancelToken? cancelToken,
  }) async {
    final query = <String, dynamic>{};
    if (status != null && status.trim().isNotEmpty) {
      query['status'] = status.trim();
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;
    if (rk != null) query['rk'] = rk;

    final res = await api.get(
      '/admin/tickets',
      queryParameters: query.isEmpty ? null : query,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          extraKeys: const ['tickets', 'items', 'rows', 'results'],
        );
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

  Future<Result<List<AdminTicketListItem>>> getMyTickets({
    String? status,
    String? search,
    int? page,
    int? limit,
    CancelToken? cancelToken,
  }) async {
    final query = <String, dynamic>{};
    if (status != null && status.trim().isNotEmpty) {
      query['status'] = status.trim();
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;

    final res = await api.get(
      '/admin/mytickets',
      queryParameters: query.isEmpty ? null : query,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          extraKeys: const ['tickets', 'items', 'rows', 'results', 'data'],
        );
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

  Future<Result<List<AdminTicketMessageItem>>> getTicketMessages(
    String ticketId, {
    int? rk,
    CancelToken? cancelToken,
  }) async {
    final query = <String, dynamic>{};
    if (rk != null) query['rk'] = rk;
    final res = await api.get(
      '/admin/tickets/$ticketId',
      queryParameters: query.isEmpty ? null : query,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          extraKeys: const ['messages', 'conversation', 'thread', 'replies'],
        );
        final out = <AdminTicketMessageItem>[];

        if (list != null) {
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              out.add(AdminTicketMessageItem(item));
            } else if (item is Map) {
              out.add(
                AdminTicketMessageItem(Map<String, dynamic>.from(item.cast())),
              );
            }
          }
          return Result.ok(out);
        }

        final single = _extractMap(data);
        if (single.isNotEmpty && _messageLike(single)) {
          out.add(AdminTicketMessageItem(single));
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<Map<String, dynamic>>> getTicketDetail(
    String ticketId, {
    int? rk,
    CancelToken? cancelToken,
  }) async {
    final query = <String, dynamic>{};
    if (rk != null) query['rk'] = rk;
    final res = await api.get(
      '/admin/tickets/$ticketId',
      queryParameters: query.isEmpty ? null : query,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        if (data is! Map) return Result.ok(const <String, dynamic>{});
        final root = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data.cast());

        Map<String, dynamic> toMap(Object? v) {
          if (v is Map<String, dynamic>) return v;
          if (v is Map) return Map<String, dynamic>.from(v.cast());
          return const <String, dynamic>{};
        }

        final l1 = toMap(root['data']);
        final l2 = toMap(l1['data']);
        if (l2.isNotEmpty) return Result.ok(l2);
        if (l1.isNotEmpty) return Result.ok(l1);
        return Result.ok(root);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<AdminTicketMessageItem>>> getMyTicketMessages(
    String ticketId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/admin/mytickets/$ticketId',
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          extraKeys: const ['messages', 'conversation', 'thread', 'replies'],
        );
        final out = <AdminTicketMessageItem>[];

        if (list != null) {
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              out.add(AdminTicketMessageItem(item));
            } else if (item is Map) {
              out.add(
                AdminTicketMessageItem(Map<String, dynamic>.from(item.cast())),
              );
            }
          }
          return Result.ok(out);
        }

        final single = _extractMap(data);
        if (single.isNotEmpty && _messageLike(single)) {
          out.add(AdminTicketMessageItem(single));
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<AdminTicketMessageItem?>> sendTicketMessage(
    String ticketId,
    String message, {
    bool internal = false,
    PickedFilePayload? attachment,
    int? rk,
    CancelToken? cancelToken,
  }) async {
    final query = <String, dynamic>{};
    if (rk != null) query['rk'] = rk;
    Result<dynamic> res;
    if (attachment != null) {
      final form = FormData.fromMap({
        'message': message,
        if (internal) 'type': 'INTERNAL',
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
        '/admin/tickets/$ticketId/messages',
        data: form,
        queryParameters: query.isEmpty ? null : query,
        cancelToken: cancelToken,
        options: Options(
          contentType: 'multipart/form-data',
          headers: const {
            'Accept': 'application/json',
          },
        ),
      );
    } else {
      final payload = <String, dynamic>{
        'message': message,
        if (internal) 'type': 'INTERNAL',
      };
      res = await api.post(
        '/admin/tickets/$ticketId/messages',
        data: payload,
        queryParameters: query.isEmpty ? null : query,
        cancelToken: cancelToken,
      );
    }

    return res.when(
      success: (data) {
        final map = _extractMap(data);
        if (map.isEmpty) return Result.ok(null);

        if (_messageLike(map)) {
          return Result.ok(AdminTicketMessageItem(map));
        }

        final list = _extractList(
          data,
          extraKeys: const ['messages', 'conversation', 'thread', 'replies'],
        );
        if (list != null && list.isNotEmpty) {
          final first = list.first;
          if (first is Map<String, dynamic>) {
            return Result.ok(AdminTicketMessageItem(first));
          }
          if (first is Map) {
            return Result.ok(
              AdminTicketMessageItem(Map<String, dynamic>.from(first.cast())),
            );
          }
        }
        return Result.ok(null);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<AdminTicketMessageItem?>> sendMyTicketMessage(
    String ticketId,
    String message, {
    bool internal = false,
    CancelToken? cancelToken,
  }) async {
    final payload = <String, dynamic>{'message': message};

    final res = await api.post(
      '/admin/mytickets/$ticketId/messages',
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final map = _extractMap(data);
        if (map.isEmpty) return Result.ok(null);

        if (_messageLike(map)) {
          return Result.ok(AdminTicketMessageItem(map));
        }

        final list = _extractList(
          data,
          extraKeys: const ['messages', 'conversation', 'thread', 'replies'],
        );
        if (list != null && list.isNotEmpty) {
          final first = list.first;
          if (first is Map<String, dynamic>) {
            return Result.ok(AdminTicketMessageItem(first));
          }
          if (first is Map) {
            return Result.ok(
              AdminTicketMessageItem(Map<String, dynamic>.from(first.cast())),
            );
          }
        }
        return Result.ok(null);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updateTicketStatus(
    String ticketId,
    String status, {
    int? rk,
    CancelToken? cancelToken,
  }) async {
    final query = <String, dynamic>{};
    if (rk != null) query['rk'] = rk;
    final res = await api.patch(
      '/admin/tickets/$ticketId/status',
      data: <String, dynamic>{'status': status},
      queryParameters: query.isEmpty ? null : query,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updateMyTicketStatus(
    String ticketId,
    String status, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.patch(
      '/admin/mytickets/$ticketId/status',
      data: <String, dynamic>{'status': status},
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> createTicket({
    required String userId,
    required String subject,
    required String message,
    String category = 'SERVER',
    String priority = 'HIGH',
    CancelToken? cancelToken,
  }) async {
    final res = await api.post(
      '/admin/tickets',
      data: <String, dynamic>{
        'fromUserId': userId,
        'userId': userId,
        'title': subject,
        'subject': subject,
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

  Future<Result<void>> createMyTicket({
    required String title,
    required String category,
    required String priority,
    required String message,
    List<PickedFilePayload> attachments = const <PickedFilePayload>[],
    CancelToken? cancelToken,
  }) async {
    Result<dynamic> res;
    if (attachments.isNotEmpty) {
      final form = FormData.fromMap({
        'title': title,
        'category': category,
        'priority': priority,
        'message': message,
        'attachments': attachments
            .map(
              (file) => MultipartFile.fromBytes(
                file.bytes,
                filename: file.filename,
              ),
            )
            .toList(),
      });
      res = await api.post(
        '/admin/mytickets',
        data: form,
        cancelToken: cancelToken,
        options: Options(
          contentType: 'multipart/form-data',
          headers: const {'Accept': 'application/json'},
        ),
      );
    } else {
      res = await api.post(
        '/admin/mytickets',
        data: <String, dynamic>{
          'title': title,
          'category': category,
          'priority': priority,
          'message': message,
        },
        cancelToken: cancelToken,
      );
    }

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
    final keys = const ['data', 'result', 'item', 'ticket'];

    for (final key in keys) {
      final value = level0[key];
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value.cast());
    }

    for (final value in level0.values) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value.cast());
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
