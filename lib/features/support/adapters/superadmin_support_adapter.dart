import 'package:dio/dio.dart';
import 'package:open_vts/core/models/ticket_message_item.dart';
import 'package:open_vts/core/network/api_client.dart';
import 'package:open_vts/core/network/result.dart';
import 'package:open_vts/core/repositories/superadmin_repository.dart';
import 'package:open_vts/features/support/support_api_mapper.dart';
import 'package:open_vts/features/support/support_models.dart';
import 'package:open_vts/features/support/support_repository.dart';

class SuperadminSupportAdapter implements SupportRepositoryAdapter {
  SuperadminSupportAdapter(ApiClient api) : _repo = SuperadminRepository(api: api);

  final SuperadminRepository _repo;

  @override
  Future<Result<void>> createTicket(
    SupportCreateTicketDraft draft, {
    CancelToken? cancelToken,
  }) {
    return _repo.createTicket(
      message: draft.message,
      priority: (draft.priority ?? 'MEDIUM').trim(),
      category: (draft.category ?? 'GENERAL').trim(),
      subject: draft.title,
      adminId: draft.adminId,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Result<Map<String, dynamic>>> getTicketDetails(
    String ticketId, {
    CancelToken? cancelToken,
    SupportListScope scope = SupportListScope.all,
  }) {
    return _repo.getTicketDetails(ticketId, cancelToken: cancelToken);
  }

  @override
  Future<Result<List<SupportTicketMessage>>> getTicketMessages(
    String ticketId, {
    CancelToken? cancelToken,
    SupportListScope scope = SupportListScope.all,
  }) async {
    final result = await _repo.getTicketDetails(
      ticketId,
      cancelToken: cancelToken,
    );
    return result.when(
      success: (raw) {
        final out = <SupportTicketMessage>[];
        final messages = raw['messages'];
        if (messages is List) {
          for (final item in messages) {
            if (item is Map<String, dynamic>) {
              out.add(fromSuperadminMessage(TicketMessageItem(item)));
            } else if (item is Map) {
              out.add(
                fromSuperadminMessage(
                  TicketMessageItem(Map<String, dynamic>.from(item.cast())),
                ),
              );
            }
          }
        }
        return Result.ok(out);
      },
      failure: (error) => Result.fail(error),
    );
  }

  @override
  Future<Result<List<SupportTicketSummary>>> getTickets(
    SupportListQuery query, {
    CancelToken? cancelToken,
  }) async {
    final result = await _repo.getTickets(
      status: query.status,
      page: query.page ?? 1,
      limit: query.limit ?? 50,
      cancelToken: cancelToken,
    );
    return result.when(
      success: (items) => Result.ok(items.map(fromSuperadminTicket).toList()),
      failure: (error) => Result.fail(error),
    );
  }

  @override
  Future<Result<SupportTicketMessage?>> sendMessage(
    SupportSendMessageDraft draft, {
    CancelToken? cancelToken,
    SupportListScope scope = SupportListScope.all,
  }) async {
    final result = await _repo.sendTicketMessage(
      draft.ticketId,
      draft.message,
      internal: draft.internal,
      attachment: draft.attachment,
      cancelToken: cancelToken,
    );
    return result.when(
      success: (item) =>
          Result.ok(item == null ? null : fromSuperadminMessage(item)),
      failure: (error) => Result.fail(error),
    );
  }

  @override
  Future<Result<void>> updateStatus(
    String ticketId,
    String status, {
    CancelToken? cancelToken,
    SupportListScope scope = SupportListScope.all,
  }) {
    return _repo.updateTicketStatus(ticketId, status, cancelToken: cancelToken);
  }

  @override
  String resolveAttachmentUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri != null && uri.hasScheme) return rawUrl;

    final base = _repo.api.dio.options.baseUrl;
    final baseUri = Uri.tryParse(base);
    if (baseUri != null) {
      final normalized = rawUrl.startsWith('/') ? rawUrl.substring(1) : rawUrl;
      return baseUri.resolve(normalized).toString();
    }
    return rawUrl;
  }
}