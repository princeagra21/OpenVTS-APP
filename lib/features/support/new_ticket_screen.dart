import 'package:flutter/material.dart';
import 'package:open_vts/core/models/admin_user_list_item.dart';
import 'package:open_vts/features/support/legacy/admin_new_ticket_screen_legacy.dart'
    as admin_legacy;
import 'package:open_vts/features/support/legacy/user_new_ticket_screen_legacy.dart'
    as user_legacy;
import 'package:open_vts/features/support/support_role_config.dart';
import 'package:open_vts/modules/superadmin/components/admin/support/new_ticket_screen.dart'
    as superadmin_legacy;

class SupportNewTicketScreen extends StatelessWidget {
  const SupportNewTicketScreen.admin({
    super.key,
    this.preSelectedUser,
    this.forMyTickets = false,
  }) : _role = SupportRole.admin;

  const SupportNewTicketScreen.user({super.key})
    : _role = SupportRole.user,
      preSelectedUser = null,
      forMyTickets = false;

  const SupportNewTicketScreen.superadmin({super.key})
    : _role = SupportRole.superadmin,
      preSelectedUser = null,
      forMyTickets = false;

  final SupportRole _role;
  final AdminUserListItem? preSelectedUser;
  final bool forMyTickets;

  @override
  Widget build(BuildContext context) {
    switch (_role) {
      case SupportRole.admin:
        return admin_legacy.NewTicketScreen(
          preSelectedUser: preSelectedUser,
          forMyTickets: forMyTickets,
        );
      case SupportRole.user:
        return const user_legacy.NewTicketScreen();
      case SupportRole.superadmin:
        return const superadmin_legacy.NewTicketScreen();
    }
  }
}
