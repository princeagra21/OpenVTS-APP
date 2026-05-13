import 'package:open_vts/features/support/data/models/support_ticket_response.dart';
import 'package:open_vts/features/support/domain/entities/support_models.dart';

class SupportTicketMapper {
  const SupportTicketMapper();

  SupportTicketSummary toSummary(SupportTicketResponse response) => fromMap(response.data);

  SupportTicketSummary fromMap(Map<String, dynamic> raw) {
    return SupportTicketSummary(
      id: _str(raw['id'] ?? raw['_id'] ?? raw['ticketId']),
      subject: _str(raw['subject'] ?? raw['title']),
      status: _str(raw['status']),
      ownerName: _str(raw['ownerName'] ?? raw['userName'] ?? raw['createdBy']),
      description: _str(raw['description'] ?? raw['message']),
      category: _str(raw['category']),
      priority: _str(raw['priority']),
      ticketNumber: _str(raw['ticketNumber'] ?? raw['ticketNo']),
      createdAt: _str(raw['createdAt']),
      updatedAt: _str(raw['updatedAt']),
      raw: raw,
    );
  }

  String _str(Object? value) => value?.toString() ?? '';
}
