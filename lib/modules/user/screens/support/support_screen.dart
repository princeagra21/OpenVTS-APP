import 'package:flutter/material.dart';
import 'package:open_vts/core/models/admin_ticket_list_item.dart';
import 'package:open_vts/features/support/support_inbox_screen.dart';
import 'package:open_vts/features/support/support_role_config.dart';
import 'package:open_vts/features/support/ticket_details/ticket_details_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SupportInboxScreen(role: SupportRole.user);
  }
}

class TicketDetailsScreen extends StatelessWidget {
  const TicketDetailsScreen({super.key, required this.ticket});

  final AdminTicketListItem ticket;

  @override
  Widget build(BuildContext context) {
    return SupportTicketDetailsScreen.user(ticket: ticket);
  }
}
