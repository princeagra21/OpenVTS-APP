import 'package:open_vts/core/utils/request_control.dart';
import 'package:open_vts/features/admin/domain/entities/admin_ticket_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_ticket_message_item.dart';
import 'package:open_vts/features/user/domain/entities/user_ticket_details.dart';
import 'package:open_vts/core/api/api_envelope.dart';
import 'package:open_vts/core/api/api_result.dart';
import 'package:open_vts/core/utils/file_picker_helper.dart';
import 'package:open_vts/core/api/api_paths.dart';
import 'package:open_vts/core/api/legacy_api_transport.dart';

class UserSupportRepository {
  final LegacyApiTransport api;

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
      UserApiPaths.tickets,
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

  Future<Result<UserTicketDetails>> getTicketDetails(
    String ticketId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      UserApiPaths.ticketDetails(ticketId),
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) => Result.ok(UserTicketDetails(_extractPayloadMap(data))),
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
        UserApiPaths.ticketDetails(ticketId),
        data: form,
        cancelToken: cancelToken,
        options: Options(
          contentType: 'multipart/form-data',
          headers: const {'Accept': 'application/json'},
        ),
      );
    } else {
      res = await api.post(
        UserApiPaths.ticketDetails(ticketId),
        data: <String, dynamic>{'message': message},
        cancelToken: cancelToken,
      );
    }

    return res.when(
      success: (data) {
        final map = _extractPayloadMap(data);
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
      UserApiPaths.tickets,
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
