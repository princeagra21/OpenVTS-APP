import 'package:fleet_stack/core/models/admin_ticket_message_item.dart';

class UserTicketDetails {
  final Map<String, dynamic> raw;

  const UserTicketDetails(this.raw);

  String get id => _string(raw['id'] ?? raw['ticketId'] ?? raw['_id']);

  String get ticketNo => _string(
    raw['ticketNo'] ?? raw['ticketNumber'] ?? raw['code'] ?? raw['reference'],
  );

  String get title =>
      _string(raw['title'] ?? raw['subject'] ?? raw['name'] ?? raw['summary']);

  String get status => _string(raw['status'] ?? raw['state']);

  String get category => _string(raw['category']);

  String get priority => _string(raw['priority']);

  String get createdAt => _string(
    raw['createdAt'] ?? raw['created_at'] ?? raw['created'] ?? raw['timestamp'],
  );

  String get updatedAt => _string(
    raw['updatedAt'] ??
        raw['updated_at'] ??
        raw['updated'] ??
        raw['lastUpdated'],
  );

  List<AdminTicketMessageItem> get messages {
    final messages = raw['messages'];
    if (messages is! List) return const <AdminTicketMessageItem>[];

    return messages
        .whereType<Map>()
        .map(
          (item) => AdminTicketMessageItem(
            item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item.cast()),
          ),
        )
        .toList();
  }

  static String normalizeStatus(String? rawStatus) {
    final value = (rawStatus ?? '').trim().toLowerCase();
    if (value.isEmpty) return '';
    if (value == 'open') return 'open';
    if (value == 'in process' ||
        value == 'in_process' ||
        value == 'inprogress') {
      return 'in_process';
    }
    if (value == 'resolved' || value == 'answer' || value == 'answered') {
      return 'resolved';
    }
    if (value == 'hold' || value == 'on hold' || value == 'on_hold') {
      return 'hold';
    }
    if (value == 'closed' || value == 'done') return 'closed';
    return value.replaceAll(' ', '_');
  }

  String get statusLabel {
    switch (normalizeStatus(status)) {
      case 'open':
        return 'Open';
      case 'in_process':
      case 'in_progress':
        return 'In Process';
      case 'resolved':
      case 'answered':
        return 'Answered';
      case 'hold':
      case 'on_hold':
        return 'Hold';
      case 'closed':
        return 'Closed';
      default:
        final fallback = status.trim();
        return fallback.isEmpty ? '—' : fallback;
    }
  }

  static String _string(Object? value) {
    if (value == null) return '';
    final out = value.toString().trim();
    if (out.toLowerCase() == 'null') return '';
    return out;
  }
}
