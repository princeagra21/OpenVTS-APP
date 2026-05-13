import 'package:open_vts/features/admin/domain/entities/admin_ticket_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_ticket_message_item.dart';
import 'package:open_vts/features/support/domain/entities/ticket_list_item.dart';
import 'package:open_vts/features/support/domain/entities/ticket_message_item.dart';
import 'package:open_vts/features/support/domain/entities/support_models.dart';

SupportTicketSummary fromAdminTicket(AdminTicketListItem item) {
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

SupportTicketSummary fromSuperadminTicket(TicketListItem item) {
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

SupportTicketMessage fromAdminMessage(AdminTicketMessageItem item) {
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

SupportTicketMessage fromSuperadminMessage(TicketMessageItem item) {
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