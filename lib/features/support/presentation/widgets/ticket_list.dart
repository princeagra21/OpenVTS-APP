import 'package:flutter/material.dart';
import 'package:open_vts/features/support/domain/entities/support_models.dart';
import 'package:open_vts/features/support/presentation/widgets/ticket_card.dart';
import 'package:open_vts/features/support/presentation/widgets/ticket_empty_state.dart';

class TicketList extends StatelessWidget {
  const TicketList({
    super.key,
    required this.tickets,
    required this.onOpenTicket,
    this.loading = false,
  });

  final List<SupportTicketSummary> tickets;
  final ValueChanged<SupportTicketSummary> onOpenTicket;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading && tickets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tickets.isEmpty) {
      return const TicketEmptyState(message: 'No tickets found');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return TicketCard(ticket: ticket, onTap: () => onOpenTicket(ticket));
      },
    );
  }
}
