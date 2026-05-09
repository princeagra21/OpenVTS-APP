import 'package:dio/dio.dart';
import 'package:open_vts/core/network/api_client.dart';
import 'package:open_vts/core/network/result.dart';
import 'package:open_vts/core/repositories/user_support_repository.dart';
import 'package:open_vts/features/support/support_api_mapper.dart';
import 'package:open_vts/features/support/support_models.dart';
import 'package:open_vts/features/support/support_repository.dart';

class UserSupportAdapter implements SupportRepositoryAdapter {
  UserSupportAdapter(ApiClient api) : _repo = UserSupportRepository(api: api);

  final UserSupportRepository _repo;

  @override
  Future<Result<void>> createTicket(
    SupportCreateTicketDraft draft, {
    CancelToken? cancelToken,
  }) {
    return _repo.createTicket(
      title: draft.title,
      category: (draft.category ?? 'GENERAL').trim(),
      priority: (draft.priority ?? 'MEDIUM').trim(),
      message: draft.message,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Result<Map<String, dynamic>>> getTicketDetails(
    String ticketId, {
    CancelToken? cancelToken,
    SupportListScope scope = SupportListScope.all,
  }) async {
    final result = await _repo.getTicketDetails(
      ticketId,
      cancelToken: cancelToken,
    );
    return result.when(
      success: (item) => Result.ok(item.raw),
      failure: (error) => Result.fail(error),
    );
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
      success: (item) =>
          Result.ok(item.messages.map(fromAdminMessage).toList()),
      failure: (error) => Result.fail(error),
    );
  }

  @override
  Future<Result<List<SupportTicketSummary>>> getTickets(
    SupportListQuery query, {
    CancelToken? cancelToken,
  }) async {
    final result = await _repo.getTickets(
      rk: query.rk,
      limit: query.limit ?? 100,
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
    final result = await _repo.sendTicketMessage(
      draft.ticketId,
      draft.message,
      attachment: draft.attachment,
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
    // User cannot update status; keep as no-op success to keep controller generic.
    return Future.value(Result.ok(null));
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