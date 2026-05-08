import 'package:flutter/material.dart';
import 'package:open_vts/core/models/admin_ticket_list_item.dart';
import 'package:open_vts/features/support/legacy/admin_support_screen_legacy.dart'
    as admin_legacy;
import 'package:open_vts/features/support/legacy/user_support_screen_legacy.dart'
    as user_legacy;
import 'package:open_vts/features/support/support_role_config.dart';
import 'package:open_vts/modules/superadmin/components/admin/support/ticket_details_screen.dart'
    as superadmin_details;

class SupportTicketDetailsScreen extends StatelessWidget {
  const SupportTicketDetailsScreen.admin({
    super.key,
    required AdminTicketListItem ticket,
    bool forMyTickets = false,
  }) : _role = SupportRole.admin,
       _adminTicket = ticket,
       _forMyTickets = forMyTickets,
       _superadminTicket = null;

  const SupportTicketDetailsScreen.user({
    super.key,
    required AdminTicketListItem ticket,
  }) : _role = SupportRole.user,
       _adminTicket = ticket,
       _forMyTickets = false,
       _superadminTicket = null;

  const SupportTicketDetailsScreen.superadmin({
    super.key,
    required superadmin_details.Ticket ticket,
  }) : _role = SupportRole.superadmin,
       _adminTicket = null,
       _forMyTickets = false,
       _superadminTicket = ticket;

  final SupportRole _role;
  final AdminTicketListItem? _adminTicket;
  final bool _forMyTickets;
  final superadmin_details.Ticket? _superadminTicket;

  @override
  Widget build(BuildContext context) {
    switch (_role) {
      case SupportRole.admin:
        return admin_legacy.TicketDetailsScreen(
          ticket: _adminTicket!,
          isMyTicket: _forMyTickets,
        );
      case SupportRole.user:
        return user_legacy.TicketDetailsScreen(ticket: _adminTicket!);
      case SupportRole.superadmin:
        return superadmin_details.TicketDetailsScreen(
          ticket: _superadminTicket!,
        );
    }
  }
}
