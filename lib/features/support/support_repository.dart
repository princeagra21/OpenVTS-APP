import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_vts/core/models/admin_ticket_list_item.dart';
import 'package:open_vts/core/models/admin_ticket_message_item.dart';
import 'package:open_vts/core/models/ticket_list_item.dart';
import 'package:open_vts/core/models/ticket_message_item.dart';
import 'package:open_vts/core/network/api_client.dart';
import 'package:open_vts/core/network/api_client_provider.dart';
import 'package:open_vts/core/network/api_envelope.dart';
import 'package:open_vts/core/network/api_paths.dart';
import 'package:open_vts/core/network/result.dart';
import 'package:open_vts/core/repositories/admin_support_repository.dart';
import 'package:open_vts/core/repositories/superadmin_repository.dart';
import 'package:open_vts/core/repositories/user_support_repository.dart';
import 'package:open_vts/core/utils/file_picker_helper.dart';
import 'package:open_vts/features/support/support_models.dart';
import 'package:open_vts/features/support/support_role_config.dart';

@immutable
class SupportSendMessageDraft {
  const SupportSendMessageDraft({
    required this.ticketId,
    required this.message,
    this.internal = false,
    this.attachment,
  });

  final String ticketId;
  final String message;
  final bool internal;
  final PickedFilePayload? attachment;
}

abstract class SupportRepositoryAdapter {
  Future<Result<List<SupportTicketSummary>>> getTickets(
    SupportListQuery query, {
    CancelToken? cancelToken,
  });

  Future<Result<List<SupportTicketMessage>>> getTicketMessages(
    String ticketId, {
    CancelToken? cancelToken,
    SupportListScope scope = SupportListScope.all,
  });

  Future<Result<Map<String, dynamic>>> getTicketDetails(
    String ticketId, {
    CancelToken? cancelToken,
    SupportListScope scope = SupportListScope.all,
  });

  Future<Result<SupportTicketMessage?>> sendMessage(
    SupportSendMessageDraft draft, {
    CancelToken? cancelToken,
    SupportListScope scope = SupportListScope.all,
  });

  Future<Result<void>> updateStatus(
    String ticketId,
    String status, {
    CancelToken? cancelToken,
    SupportListScope scope = SupportListScope.all,
  });

  Future<Result<void>> createTicket(
    SupportCreateTicketDraft draft, {
    CancelToken? cancelToken,
  });
}

class SupportRepositoryFactory {
  const SupportRepositoryFactory._();

  static SupportRepositoryAdapter forRole(SupportRole role, {ApiClient? api}) {
    final resolved = api ?? ApiClientProvider.shared();
    switch (role) {
      case SupportRole.admin:
        return _AdminSupportAdapter(AdminSupportRepository(api: resolved));
      case SupportRole.user:
        return _UserSupportAdapter(UserSupportRepository(api: resolved));
      case SupportRole.superadmin:
        return _SuperadminSupportAdapter(SuperadminRepository(api: resolved));
    }
  }
}

class _AdminSupportAdapter implements SupportRepositoryAdapter {
  _AdminSupportAdapter(this._repo);

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
      success: (items) => Result.ok(items.map(_fromAdminMessage).toList()),
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
        success: (items) => Result.ok(items.map(_fromAdminTicket).toList()),
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
      success: (items) => Result.ok(items.map(_fromAdminTicket).toList()),
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
          Result.ok(item == null ? null : _fromAdminMessage(item)),
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
}

class _UserSupportAdapter implements SupportRepositoryAdapter {
  _UserSupportAdapter(this._repo);

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
          Result.ok(item.messages.map(_fromAdminMessage).toList()),
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
      success: (items) => Result.ok(items.map(_fromAdminTicket).toList()),
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
          Result.ok(item == null ? null : _fromAdminMessage(item)),
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
}

class _SuperadminSupportAdapter implements SupportRepositoryAdapter {
  _SuperadminSupportAdapter(this._repo);

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
              out.add(_fromSuperadminMessage(TicketMessageItem(item)));
            } else if (item is Map) {
              out.add(
                _fromSuperadminMessage(
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
      success: (items) => Result.ok(items.map(_fromSuperadminTicket).toList()),
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
          Result.ok(item == null ? null : _fromSuperadminMessage(item)),
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
}

SupportTicketSummary _fromAdminTicket(AdminTicketListItem item) {
  return SupportTicketSummary(
    id: item.id,
    subject: item.subject,
    status: item.statusLabel,
    ownerName: item.ownerName,
    description: item.description,
    category: item.category,
    priority: item.priority,
    ticketNumber: item.ticketNumber,
    createdAt: item.createdAt,
    updatedAt: item.updatedAt,
    raw: item.raw,
  );
}

SupportTicketSummary _fromSuperadminTicket(TicketListItem item) {
  return SupportTicketSummary(
    id: item.id,
    subject: item.subject,
    status: item.status,
    ownerName: item.ownerName.isEmpty ? item.userName : item.ownerName,
    description: item.snippet,
    category: item.raw['category']?.toString() ?? '',
    priority: item.priority,
    ticketNumber: item.ticketNumber,
    createdAt: item.createdAt,
    updatedAt: item.raw['updatedAt']?.toString() ?? '',
    raw: item.raw,
  );
}

SupportTicketMessage _fromAdminMessage(AdminTicketMessageItem item) {
  return SupportTicketMessage(
    id: item.id,
    senderName: item.senderName,
    senderId: item.raw['senderId']?.toString() ?? '',
    message: item.message,
    createdAt: item.createdAt,
    isInternal: item.isInternal,
    attachmentName: item.raw['attachmentName']?.toString() ?? '',
    attachmentUrl: item.raw['attachmentUrl']?.toString() ?? '',
    raw: item.raw,
  );
}

SupportTicketMessage _fromSuperadminMessage(TicketMessageItem item) {
  return SupportTicketMessage(
    id: item.id,
    senderName: item.senderName,
    senderId: item.senderId,
    message: item.message,
    createdAt: item.createdAt,
    isInternal: item.isInternal,
    attachmentName: item.attachmentName,
    attachmentUrl: item.attachmentUrl,
    raw: item.raw,
  );
}
