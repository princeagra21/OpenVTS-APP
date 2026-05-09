import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_vts/core/utils/file_picker_helper.dart';
import 'package:open_vts/features/support/support_models.dart';
import 'package:open_vts/features/support/support_role_config.dart';

class TicketDetailsState {
  final SupportRole role;
  final SupportListScope scope;
  final SupportTicketSummary initialTicket;

  SupportTicketSummary ticket;
  String selectedStatus;
  bool loading;
  bool sending;
  bool updatingStatus;
  bool hasChanges;
  String? errorMessage;
  List<SupportTicketMessage> messages;
  PickedFilePayload? attachment;
  String selectedComposerTab;
  TextEditingController messageController;

  CancelToken? detailsToken;
  CancelToken? messagesToken;
  CancelToken? sendToken;
  CancelToken? statusToken;

  TicketDetailsState({
    required this.role,
    required this.scope,
    required this.initialTicket,
  }) : ticket = initialTicket,
       selectedStatus = _normalizeStatusLabel(initialTicket.status),
       loading = false,
       sending = false,
       updatingStatus = false,
       hasChanges = false,
       errorMessage = null,
       messages = <SupportTicketMessage>[],
       attachment = null,
       selectedComposerTab = 'Conversation',
       messageController = TextEditingController();

  TicketDetailsState copyWith({
    SupportTicketSummary? ticket,
    String? selectedStatus,
    bool? loading,
    bool? sending,
    bool? updatingStatus,
    bool? hasChanges,
    String? errorMessage,
    List<SupportTicketMessage>? messages,
    PickedFilePayload? attachment,
    String? selectedComposerTab,
    CancelToken? detailsToken,
    CancelToken? messagesToken,
    CancelToken? sendToken,
    CancelToken? statusToken,
  }) {
    return TicketDetailsState._internal(
      role: role,
      scope: scope,
      initialTicket: initialTicket,
      ticket: ticket ?? this.ticket,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      updatingStatus: updatingStatus ?? this.updatingStatus,
      hasChanges: hasChanges ?? this.hasChanges,
      errorMessage: errorMessage ?? this.errorMessage,
      messages: messages ?? this.messages,
      attachment: attachment ?? this.attachment,
      selectedComposerTab: selectedComposerTab ?? this.selectedComposerTab,
      messageController: messageController,
      detailsToken: detailsToken ?? this.detailsToken,
      messagesToken: messagesToken ?? this.messagesToken,
      sendToken: sendToken ?? this.sendToken,
      statusToken: statusToken ?? this.statusToken,
    );
  }

  TicketDetailsState._internal({
    required this.role,
    required this.scope,
    required this.initialTicket,
    required this.ticket,
    required this.selectedStatus,
    required this.loading,
    required this.sending,
    required this.updatingStatus,
    required this.hasChanges,
    required this.errorMessage,
    required this.messages,
    required this.attachment,
    required this.selectedComposerTab,
    required this.messageController,
    required this.detailsToken,
    required this.messagesToken,
    required this.sendToken,
    required this.statusToken,
  });

  static String _normalizeStatusLabel(String raw) {
    final value = raw
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');
    if (value.isEmpty) {
      return 'Open';
    }
    if (value.contains('close')) {
      return 'Closed';
    }
    if (value.contains('answer') || value.contains('resolve')) {
      return 'Answered';
    }
    if (value.contains('hold')) {
      return 'Hold';
    }
    if (value.contains('process') ||
        value.contains('progress') ||
        value.contains('pending')) {
      return 'In Process';
    }
    if (value.contains('open') || value.contains('new')) {
      return 'Open';
    }
    return raw.trim();
  }

  void dispose() {
    detailsToken?.cancel('TicketDetailsState disposed');
    messagesToken?.cancel('TicketDetailsState disposed');
    sendToken?.cancel('TicketDetailsState disposed');
    statusToken?.cancel('TicketDetailsState disposed');
    messageController.dispose();
  }
}