import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_vts/core/network/api_client.dart';
import 'package:open_vts/core/network/api_client_provider.dart';
import 'package:open_vts/core/network/result.dart';
import 'package:open_vts/core/utils/file_picker_helper.dart';
import 'package:open_vts/features/support/adapters/admin_support_adapter.dart';
import 'package:open_vts/features/support/adapters/superadmin_support_adapter.dart';
import 'package:open_vts/features/support/adapters/user_support_adapter.dart';
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

  String resolveAttachmentUrl(String rawUrl);
}

class SupportRepositoryFactory {
  const SupportRepositoryFactory._();

  static SupportRepositoryAdapter forRole(SupportRole role, {ApiClient? api}) {
    final resolved = api ?? ApiClientProvider.shared();
    switch (role) {
      case SupportRole.admin:
        return AdminSupportAdapter(resolved);
      case SupportRole.user:
        return UserSupportAdapter(resolved);
      case SupportRole.superadmin:
        return SuperadminSupportAdapter(resolved);
    }
  }
}