import 'package:dio/dio.dart';
import 'package:open_vts/core/models/admin_ticket_list_item.dart';
import 'package:open_vts/core/models/admin_ticket_message_item.dart';
import 'package:open_vts/core/network/api_client.dart';
import 'package:open_vts/core/network/api_envelope.dart';
import 'package:open_vts/core/network/result.dart';
import 'package:open_vts/core/utils/file_picker_helper.dart';
import 'package:open_vts/core/network/api_paths.dart';

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
      AdminApiPaths.tickets,
      queryParameters: query.isEmpty ? null : query,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractMapList(
          data,
          extraKeys: const ['tickets', 'items', 'rows', 'results'],
        );
        final out = <AdminTicketListItem>[];
        for (final item in list) {
          out.add(AdminTicketListItem(item));
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
      AdminApiPaths.myTickets,
      queryParameters: query.isEmpty ? null : query,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractMapList(
          data,
          extraKeys: const ['tickets', 'items', 'rows', 'results', 'data'],
        );
        final out = <AdminTicketListItem>[];
        for (final item in list) {
          out.add(AdminTicketListItem(item));
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
      AdminApiPaths.ticketDetails(ticketId),
      queryParameters: query.isEmpty ? null : query,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractMapList(
          data,
          extraKeys: const ['messages', 'conversation', 'thread', 'replies'],
        );
        final out = <AdminTicketMessageItem>[];

        if (list.isNotEmpty) {
          for (final item in list) {
            out.add(AdminTicketMessageItem(item));
          }
          return Result.ok(out);
        }

        final single = _extractPayloadMap(data);
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
      AdminApiPaths.ticketDetails(ticketId),
      queryParameters: query.isEmpty ? null : query,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) => Result.ok(_extractPayloadMap(data)),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<AdminTicketMessageItem>>> getMyTicketMessages(
    String ticketId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      AdminApiPaths.myTicketDetails(ticketId),
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractMapList(
          data,
          extraKeys: const ['messages', 'conversation', 'thread', 'replies'],
        );
        final out = <AdminTicketMessageItem>[];

        if (list.isNotEmpty) {
          for (final item in list) {
            out.add(AdminTicketMessageItem(item));
          }
          return Result.ok(out);
        }

        final single = _extractPayloadMap(data);
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
        AdminApiPaths.ticketMessages(ticketId),
        data: form,
        queryParameters: query.isEmpty ? null : query,
        cancelToken: cancelToken,
        options: Options(
          contentType: 'multipart/form-data',
          headers: const {'Accept': 'application/json'},
        ),
      );
    } else {
      final payload = <String, dynamic>{
        'message': message,
        if (internal) 'type': 'INTERNAL',
      };
      res = await api.post(
        AdminApiPaths.ticketMessages(ticketId),
        data: payload,
        queryParameters: query.isEmpty ? null : query,
        cancelToken: cancelToken,
      );
    }

    return res.when(
      success: (data) {
        final map = _extractPayloadMap(data);
        if (map.isEmpty) return Result.ok(null);

        if (_messageLike(map)) {
          return Result.ok(AdminTicketMessageItem(map));
        }

        final list = _extractMapList(
          data,
          extraKeys: const ['messages', 'conversation', 'thread', 'replies'],
        );
        if (list.isNotEmpty) {
          return Result.ok(AdminTicketMessageItem(list.first));
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
      AdminApiPaths.myTicketMessages(ticketId),
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final map = _extractPayloadMap(data);
        if (map.isEmpty) return Result.ok(null);

        if (_messageLike(map)) {
          return Result.ok(AdminTicketMessageItem(map));
        }

        final list = _extractMapList(
          data,
          extraKeys: const ['messages', 'conversation', 'thread', 'replies'],
        );
        if (list.isNotEmpty) {
          return Result.ok(AdminTicketMessageItem(list.first));
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
      AdminApiPaths.ticketStatus(ticketId),
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
      AdminApiPaths.myTicketStatus(ticketId),
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
      AdminApiPaths.tickets,
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
              (file) =>
                  MultipartFile.fromBytes(file.bytes, filename: file.filename),
            )
            .toList(),
      });
      res = await api.post(
        AdminApiPaths.myTickets,
        data: form,
        cancelToken: cancelToken,
        options: Options(
          contentType: 'multipart/form-data',
          headers: const {'Accept': 'application/json'},
        ),
      );
    } else {
      res = await api.post(
        AdminApiPaths.myTickets,
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

  Map<String, dynamic> _extractPayloadMap(
    Object? data, {
    List<String> mapKeys = const <String>[
      'data',
      'result',
      'item',
      'ticket',
      'payload',
      'response',
    ],
  }) {
    return ApiEnvelope.payload(data, mapKeys: mapKeys);
  }

  List<Map<String, dynamic>> _extractMapList(
    Object? data, {
    List<String> extraKeys = const <String>[],
  }) {
    return ApiEnvelope.mapList(
      data,
      listKeys: <String>['data', 'items', 'result', 'results', ...extraKeys],
      maxDepth: 6,
    );
  }
}
