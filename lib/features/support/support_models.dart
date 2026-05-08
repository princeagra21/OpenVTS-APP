import 'package:flutter/foundation.dart';

enum SupportListScope { all, mine }

enum SupportTabFilter { all, open, inProcess, answered, hold, closed }

@immutable
class SupportTicketSummary {
  const SupportTicketSummary({
    required this.id,
    required this.subject,
    required this.status,
    required this.ownerName,
    required this.description,
    required this.category,
    required this.priority,
    required this.ticketNumber,
    required this.createdAt,
    required this.updatedAt,
    required this.raw,
  });

  final String id;
  final String subject;
  final String status;
  final String ownerName;
  final String description;
  final String category;
  final String priority;
  final String ticketNumber;
  final String createdAt;
  final String updatedAt;
  final Map<String, dynamic> raw;
}

@immutable
class SupportTicketMessage {
  const SupportTicketMessage({
    required this.id,
    required this.senderName,
    required this.senderId,
    required this.message,
    required this.createdAt,
    required this.isInternal,
    required this.attachmentName,
    required this.attachmentUrl,
    required this.raw,
  });

  final String id;
  final String senderName;
  final String senderId;
  final String message;
  final String createdAt;
  final bool isInternal;
  final String attachmentName;
  final String attachmentUrl;
  final Map<String, dynamic> raw;
}

@immutable
class SupportListQuery {
  const SupportListQuery({
    this.search,
    this.status,
    this.page,
    this.limit,
    this.rk,
    this.scope = SupportListScope.all,
  });

  final String? search;
  final String? status;
  final int? page;
  final int? limit;
  final int? rk;
  final SupportListScope scope;
}

@immutable
class SupportCreateTicketDraft {
  const SupportCreateTicketDraft({
    required this.title,
    required this.message,
    this.category,
    this.priority,
    this.userId,
    this.adminId,
  });

  final String title;
  final String message;
  final String? category;
  final String? priority;
  final String? userId;
  final String? adminId;
}
