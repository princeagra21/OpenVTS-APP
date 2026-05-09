import 'package:dio/dio.dart';
import 'package:open_vts/core/network/api_client.dart';
import 'package:open_vts/core/network/api_envelope.dart';
import 'package:open_vts/core/network/api_paths.dart';
import 'package:open_vts/core/network/result.dart';
import 'package:open_vts/core/repositories/admin_support_repository.dart';
import 'package:open_vts/features/support/support_api_mapper.dart';
import 'package:open_vts/features/support/support_models.dart';
import 'package:open_vts/features/support/support_repository.dart';

class AdminSupportAdapter implements SupportRepositoryAdapter {
  AdminSupportAdapter(ApiClient api) : _repo = AdminSupportRepository(api: api);

  final AdminSupportRepository _repo;

  @override
  Future<Result<void>> createTicket(
    SupportCreateTicketDraft draft, {
    CancelToken? cancelToken,
  }) {
    final category = (draft.category ?? 'SERVER').trim();
    final priority = (draft.priority ?? 'MEDIUM').trim();

    if ((draft.userId ?? '').trim().isNotEmpty) {
      return _repo.createTicket(
        userId: draft.userId!.trim(),
        subject: draft.title,
        message: draft.message,
        category: category,
        priority: priority,
        cancelToken: cancelToken,
      );
    }

    return _repo.createMyTicket(
      title: draft.title,
      category: category,
      priority: priority,
      message: draft.message,
      attachments: draft.attachments,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Result<Map<String, dynamic>>> getTicketDetails(
    String ticketId, {
    CancelToken? cancelToken,
    SupportListScope scope = SupportListScope.all,
  }) async {
    if (scope == SupportListScope.mine) {
      final result = await _repo.api.get(
        AdminApiPaths.myTicketDetails(ticketId),
        cancelToken: cancelToken,
      );
      return result.when(
        success: (data) => Result.ok(ApiEnvelope.payload(data)),
        failure: (error) => Result.fail(error),
      );
    }

    return _repo.getTicketDetail(
      ticketId,
      rk: DateTime.now().millisecondsSinceEpoch,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Result<List<SupportTicketMessage>>> getTicketMessages(
    String ticketId, {
    CancelToken? cancelToken,
    SupportListScope scope = SupportListScope.all,
  }) async {
    final result = scope == SupportListScope.mine
        ? await _repo.getMyTicketMessages(ticketId, cancelToken: cancelToken)
        : await _repo.getTicketMessages(
            ticketId,
            rk: DateTime.now().millisecondsSinceEpoch,
            cancelToken: cancelToken,
          );
    return result.when(
      success: (items) => Result.ok(items.map(fromAdminMessage).toList()),
      failure: (error) => Result.fail(error),
    );
  }

  @override
  Future<Result<List<SupportTicketSummary>>> getTickets(
    SupportListQuery query, {
    CancelToken? cancelToken,
  }) async {
    if (query.scope == SupportListScope.mine) {
      final result = await _repo.getMyTickets(
        status: query.status,
        search: query.search,
        page: query.page,
        limit: query.limit ?? 100,
        cancelToken: cancelToken,
      );
      return result.when(
        success: (items) => Result.ok(items.map(fromAdminTicket).toList()),
        failure: (error) => Result.fail(error),
      );
    }

    final result = await _repo.getTickets(
      status: query.status,
      search: query.search,
      page: query.page,
      limit: query.limit ?? 100,
      rk: query.rk,
      cancelToken: cancelToken,
    );
    return result.when(
      success: (items) => Result.ok(items.map(fromAdminTicket).toList()),
      failure: (error) => Result.fail(error),
    );
  }

  @override
  Future<Result<SupportTicketMessage?>> sendMessage(
    SupportSendMessageDraft draft, {
    CancelToken? cancelToken,
    SupportListScope scope = SupportListScope.all,
  }) async {
    final result = scope == SupportListScope.mine
        ? await _repo.sendMyTicketMessage(
            draft.ticketId,
            draft.message,
            internal: draft.internal,
            cancelToken: cancelToken,
          )
        : await _repo.sendTicketMessage(
            draft.ticketId,
            draft.message,
            internal: draft.internal,
            attachment: draft.attachment,
            rk: DateTime.now().millisecondsSinceEpoch,
            cancelToken: cancelToken,
          );
    return result.when(
      success: (item) =>
          Result.ok(item == null ? null : fromAdminMessage(item)),
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
    if (scope == SupportListScope.mine) {
      return _repo.updateMyTicketStatus(
        ticketId,
        status,
        cancelToken: cancelToken,
      );
    }

    return _repo.updateTicketStatus(
      ticketId,
      status,
      rk: DateTime.now().millisecondsSinceEpoch,
      cancelToken: cancelToken,
    );
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