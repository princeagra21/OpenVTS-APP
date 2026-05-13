import 'package:flutter/material.dart';
import 'package:open_vts/features/admin/domain/entities/admin_ticket_list_item.dart';
import 'package:open_vts/features/support/presentation/screens/support_inbox_screen.dart';
import 'package:open_vts/features/support/domain/config/support_role_config.dart';
import 'package:open_vts/features/support/presentation/ticket_details/ticket_details_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SupportInboxScreen(role: SupportRole.admin);
  }
}

class TicketDetailsScreen extends StatelessWidget {
  const TicketDetailsScreen({
    super.key,
    required this.ticket,
    this.forMyTickets = false,
  });

  final AdminTicketListItem ticket;
  final bool forMyTickets;

  @override
  Widget build(BuildContext context) {
    return SupportTicketDetailsScreen.admin(
      ticket: ticket,
      forMyTickets: forMyTickets,
    );
  }
}
