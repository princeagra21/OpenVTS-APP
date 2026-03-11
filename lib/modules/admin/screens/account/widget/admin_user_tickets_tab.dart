import 'package:fleet_stack/core/models/admin_ticket_list_item.dart';
import 'package:fleet_stack/modules/admin/screens/account/widget/admin_user_details_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUserTicketsTab extends StatelessWidget {
  final List<AdminTicketListItem> items;
  final bool loading;
  final double bodyFontSize;
  final double smallFontSize;

  const AdminUserTicketsTab({
    super.key,
    required this.items,
    required this.loading,
    required this.bodyFontSize,
    required this.smallFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (loading) {
      return listShimmer(context, count: 3, height: 102);
    }
    if (items.isEmpty) {
      return emptyStateCard(
        context,
        title: 'No tickets found',
        subtitle: 'This user has no support tickets yet.',
      );
    }

    return Column(
      children: items.map((ticket) {
        final summary = safeText(
          ticket.description.isNotEmpty
              ? ticket.description
              : '${safeText(ticket.category)} • ${safeText(ticket.priority)}',
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: detailsCard(
            context,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        safeText(ticket.subject),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: bodyFontSize + 1,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    statusChip(context, ticket.statusLabel, smallFontSize),
                  ],
                ),
                const SizedBox(height: 12),
                detailLine(
                  context,
                  'Ticket',
                  safeText(ticket.ticketNumber),
                  bodyFontSize,
                ),
                const SizedBox(height: 8),
                detailLine(context, 'Summary', summary, bodyFontSize),
                const SizedBox(height: 8),
                detailLine(
                  context,
                  'Created',
                  formatDateLabel(ticket.createdAt),
                  bodyFontSize,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
