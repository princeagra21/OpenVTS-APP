import 'package:flutter/material.dart';
import 'package:open_vts/core/utils/file_picker_helper.dart';
import 'package:open_vts/features/support/domain/entities/support_models.dart';
import 'package:open_vts/features/support/domain/config/support_role_config.dart';

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

  int detailsRequestId;
  int messagesRequestId;
  int sendRequestId;
  int statusRequestId;

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
       messageController = TextEditingController(),
       detailsRequestId = 0,
       messagesRequestId = 0,
       sendRequestId = 0,
       statusRequestId = 0;

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
    int? detailsRequestId,
    int? messagesRequestId,
    int? sendRequestId,
    int? statusRequestId,
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
      detailsRequestId: detailsRequestId ?? this.detailsRequestId,
      messagesRequestId: messagesRequestId ?? this.messagesRequestId,
      sendRequestId: sendRequestId ?? this.sendRequestId,
      statusRequestId: statusRequestId ?? this.statusRequestId,
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
    required this.detailsRequestId,
    required this.messagesRequestId,
    required this.sendRequestId,
    required this.statusRequestId,
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
    detailsRequestId++;
    messagesRequestId++;
    sendRequestId++;
    statusRequestId++;
    messageController.dispose();
  }
}
