import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_card.dart';
import 'package:open_vts/features/support/domain/entities/support_models.dart';
import 'package:open_vts/features/support/presentation/widgets/ticket_status_chip.dart';

class TicketCard extends StatelessWidget {
  const TicketCard({super.key, required this.ticket, required this.onTap});

  final SupportTicketSummary ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return OpenVtsCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.subject.isEmpty ? 'Support Ticket' : ticket.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TicketStatusChip(status: ticket.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            ticket.ticketNumber.isEmpty ? ticket.id : ticket.ticketNumber,
            style: AppFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.65),
            ),
          ),
          if (ticket.ownerName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              ticket.ownerName,
              style: AppFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
          if (ticket.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              ticket.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.roboto(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
