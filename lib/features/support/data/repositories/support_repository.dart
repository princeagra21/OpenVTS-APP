import 'package:open_vts/core/utils/request_control.dart';
import 'package:flutter/foundation.dart';
import 'package:open_vts/core/api/legacy_transport_provider.dart';
import 'package:open_vts/core/api/api_result.dart';
import 'package:open_vts/core/utils/file_picker_helper.dart';
import 'package:open_vts/features/support/data/adapters/admin_support_adapter.dart';
import 'package:open_vts/features/support/data/adapters/superadmin_support_adapter.dart';
import 'package:open_vts/features/support/data/adapters/user_support_adapter.dart';
import 'package:open_vts/features/support/domain/entities/support_models.dart';
import 'package:open_vts/features/support/domain/config/support_role_config.dart';

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

  static SupportRepositoryAdapter forRole(SupportRole role, {dynamic api}) {
    final resolved = api ?? sharedLegacyTransport();
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