import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_vts/core/network/api_exception.dart';
import 'package:open_vts/core/utils/file_picker_helper.dart';
import 'package:open_vts/design_system/components/open_vts_feedback.dart';
import 'package:open_vts/features/support/support_models.dart';
import 'package:open_vts/features/support/support_repository.dart';
import 'package:open_vts/features/support/support_role_config.dart';
import 'package:open_vts/features/support/ticket_details/ticket_details_state.dart';
import 'package:url_launcher/url_launcher.dart';

class TicketDetailsController {
  final TicketDetailsState state;
  final SupportRoleConfig config;
  final SupportRepositoryAdapter repository;

  TicketDetailsController({
    required this.state,
    required this.config,
    required this.repository,
  });

  static SupportRoleConfig configFor(SupportRole role) {
    switch (role) {
      case SupportRole.admin:
        return SupportRoleConfigs.admin;
      case SupportRole.user:
        return SupportRoleConfigs.user;
      case SupportRole.superadmin:
        return SupportRoleConfigs.superadmin;
    }
  }

  String _pickFirstNonEmpty(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return '';
  }

  String _statusToApi(String display) {
    final normalized = _normalizeStatusLabel(display).toLowerCase();
    if (normalized == 'open') return 'OPEN';
    if (normalized == 'in process') return 'IN_PROGRESS';
    if (normalized == 'closed') return 'CLOSED';
    if (normalized == 'answered') return 'ANSWERED';
    if (normalized == 'hold') return 'HOLD';
    return normalized.toUpperCase().replaceAll(' ', '_');
  }

  String _normalizeStatusLabel(String raw) {
    final value = raw
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');
    if (value.isEmpty) return 'Open';
    if (value.contains('close')) return 'Closed';
    if (value.contains('answer') || value.contains('resolve')) {
      return 'Answered';
    }
    if (value.contains('hold')) return 'Hold';
    if (value.contains('process') ||
        value.contains('progress') ||
        value.contains('pending')) {
      return 'In Process';
    }
    if (value.contains('open') || value.contains('new')) return 'Open';
    return raw.trim();
  }

  void _showInfo(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }
    OpenVtsFeedback.info(context, message);
  }

  void _showSuccess(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }
    OpenVtsFeedback.success(context, message);
  }

  void _showError(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }
    OpenVtsFeedback.error(context, message);
  }

  List<String> get statusOptions {
    final base = switch (config.role) {
      SupportRole.admin => <String>['Open', 'In Process', 'Answered', 'Closed'],
      SupportRole.user => <String>[],
      SupportRole.superadmin => <String>['Open', 'In Process', 'Closed'],
    };
    if (!base.contains(state.selectedStatus)) {
      base.insert(0, state.selectedStatus);
    }
    return base;
  }

  SupportTicketSummary _mergeTicket(
    SupportTicketSummary current,
    Map<String, dynamic> raw,
  ) {
    final mergedRaw = <String, dynamic>{...current.raw, ...raw};

    final id = _pickFirstNonEmpty(raw, const <String>['id', '_id', 'ticketId']);
    final subject = _pickFirstNonEmpty(raw, const <String>['subject', 'title']);
    final status = _pickFirstNonEmpty(raw, const <String>['status', 'state']);
    final owner = _pickFirstNonEmpty(raw, const <String>[
      'ownerName',
      'owner',
      'userName',
      'name',
    ]);
    final description = _pickFirstNonEmpty(raw, const <String>[
      'description',
      'message',
      'snippet',
    ]);
    final category = _pickFirstNonEmpty(raw, const <String>['category']);
    final priority = _pickFirstNonEmpty(raw, const <String>['priority']);
    final ticketNo = _pickFirstNonEmpty(raw, const <String>[
      'ticketNumber',
      'ticketNo',
      'code',
    ]);
    final created = _pickFirstNonEmpty(raw, const <String>[
      'createdAt',
      'created_at',
      'created',
    ]);
    final updated = _pickFirstNonEmpty(raw, const <String>[
      'updatedAt',
      'updated_at',
      'updated',
    ]);

    return SupportTicketSummary(
      id: id.isNotEmpty ? id : current.id,
      subject: subject.isNotEmpty ? subject : current.subject,
      status: status.isNotEmpty
          ? _normalizeStatusLabel(status)
          : current.status,
      ownerName: owner.isNotEmpty ? owner : current.ownerName,
      description: description.isNotEmpty ? description : current.description,
      category: category.isNotEmpty ? category : current.category,
      priority: priority.isNotEmpty ? priority : current.priority,
      ticketNumber: ticketNo.isNotEmpty ? ticketNo : current.ticketNumber,
      createdAt: created.isNotEmpty ? created : current.createdAt,
      updatedAt: updated.isNotEmpty ? updated : current.updatedAt,
      raw: mergedRaw,
    );
  }

  Future<void> loadTicketData() async {
    state.detailsToken?.cancel('Reload ticket details');
    state.messagesToken?.cancel('Reload ticket messages');
    final detailsToken = CancelToken();
    final messagesToken = CancelToken();
    state.detailsToken = detailsToken;
    state.messagesToken = messagesToken;

    state.loading = true;
    state.errorMessage = null;

    final detailsResult = await repository.getTicketDetails(
      state.ticket.id,
      scope: state.scope,
      cancelToken: detailsToken,
    );

    if (detailsToken.isCancelled) return;

    detailsResult.when(
      success: (raw) {
        state.ticket = _mergeTicket(state.ticket, raw);
        state.selectedStatus = _normalizeStatusLabel(state.ticket.status);
      },
      failure: (error) {
        state.errorMessage = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't load ticket details.";
      },
    );

    final messagesResult = await repository.getTicketMessages(
      state.ticket.id,
      scope: state.scope,
      cancelToken: messagesToken,
    );

    if (messagesToken.isCancelled) return;

    messagesResult.when(
      success: (items) {
        state.messages = items;
      },
      failure: (error) {
        state.messages = <SupportTicketMessage>[];
        state.errorMessage ??=
            error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't load ticket messages.";
      },
    );

    state.loading = false;
  }

  Future<void> reloadMessages() async {
    state.messagesToken?.cancel('Reload ticket messages');
    final token = CancelToken();
    state.messagesToken = token;

    final result = await repository.getTicketMessages(
      state.ticket.id,
      scope: state.scope,
      cancelToken: token,
    );

    if (token.isCancelled) return;

    result.when(
      success: (items) {
        state.messages = items;
      },
      failure: (_) {},
    );
  }

  Future<void> sendMessage(BuildContext context) async {
    final text = state.messageController.text.trim();
    if (text.isEmpty && state.attachment == null) return;

    state.sendToken?.cancel('Send ticket message');
    final token = CancelToken();
    state.sendToken = token;

    state.sending = true;

    final result = await repository.sendMessage(
      SupportSendMessageDraft(
        ticketId: state.ticket.id,
        message: text,
        internal:
            config.permissions.canSendInternalNotes &&
            state.selectedComposerTab == 'Internal Note',
        attachment: state.attachment,
      ),
      scope: state.scope,
      cancelToken: token,
    );

    if (token.isCancelled) return;

    result.when(
      success: (_) {
        state.sending = false;
        state.hasChanges = true;
        state.attachment = null;
        state.messageController.clear();
        reloadMessages();
      },
      failure: (error) {
        state.sending = false;
        final message = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't send message.";
        if (context.mounted) {
          _showError(context, message);
        }
      },
    );
  }

  Future<void> updateStatus(BuildContext context) async {
    if (!config.permissions.canUpdateStatus || state.updatingStatus) return;

    final current = _normalizeStatusLabel(state.ticket.status);
    if (_normalizeStatusLabel(state.selectedStatus) == current) return;

    state.statusToken?.cancel('Update ticket status');
    final token = CancelToken();
    state.statusToken = token;

    state.updatingStatus = true;

    final result = await repository.updateStatus(
      state.ticket.id,
      _statusToApi(state.selectedStatus),
      scope: state.scope,
      cancelToken: token,
    );

    if (token.isCancelled) return;

    result.when(
      success: (_) {
        state.updatingStatus = false;
        state.hasChanges = true;
        state.ticket = SupportTicketSummary(
          id: state.ticket.id,
          subject: state.ticket.subject,
          status: state.selectedStatus,
          ownerName: state.ticket.ownerName,
          description: state.ticket.description,
          category: state.ticket.category,
          priority: state.ticket.priority,
          ticketNumber: state.ticket.ticketNumber,
          createdAt: state.ticket.createdAt,
          updatedAt: state.ticket.updatedAt,
          raw: <String, dynamic>{...state.ticket.raw, 'status': state.selectedStatus},
        );
        _showSuccess(context, 'Status updated.');
      },
      failure: (error) {
        state.updatingStatus = false;
        final message = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't update status.";
        _showError(context, message);
      },
    );
  }

  Future<void> pickAttachment() async {
    final file = await pickSingleFilePayload();
    if (file == null) return;
    state.attachment = file;
  }

  Future<void> openAttachment(BuildContext context, SupportTicketMessage message) async {
    final raw = message.attachmentUrl.trim();
    if (raw.isEmpty) {
      _showInfo(context, 'Attachment URL not available.');
      return;
    }

    final resolvedUrl = repository.resolveAttachmentUrl(raw);
    final uri = Uri.tryParse(resolvedUrl);
    if (uri == null) {
      _showError(context, 'Invalid attachment URL.');
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      _showError(context, "Couldn't open attachment.");
    }
  }

  List<SupportTicketMessage> get visibleMessages {
    if (config.permissions.canSendInternalNotes &&
        state.selectedComposerTab == 'Internal Note') {
      return state.messages.where((message) => message.isInternal).toList();
    }
    return state.messages.where((message) => !message.isInternal).toList();
  }
}