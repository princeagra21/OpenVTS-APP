import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/features/support/presentation/ticket_details/ticket_details_state.dart';
import 'package:open_vts/features/support/presentation/widgets/ticket_status_chip.dart';

class TicketDetailsHeader extends StatelessWidget {
  const TicketDetailsHeader({
    super.key,
    required this.state,
  });

  final TicketDetailsState state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.ticket.subject.isEmpty
                    ? 'Support Ticket'
                    : state.ticket.subject,
                style: AppFonts.roboto(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.ticket.ticketNumber.isEmpty
                    ? state.ticket.id
                    : state.ticket.ticketNumber,
                style: AppFonts.roboto(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.62),
                ),
              ),
              if (state.ticket.ownerName.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  state.ticket.ownerName,
                  style: AppFonts.roboto(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        TicketStatusChip(status: state.ticket.status),
      ],
    );
  }
}
