import 'package:flutter/material.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/support/presentation/new_ticket/new_ticket_screen.dart';

class NewTicketScreen extends StatelessWidget {
  const NewTicketScreen({
    super.key,
    this.preSelectedUser,
    this.forMyTickets = false,
  });

  final AdminUserListItem? preSelectedUser;
  final bool forMyTickets;

  @override
  Widget build(BuildContext context) {
    return SupportNewTicketScreen.admin(
      preSelectedUser: preSelectedUser,
      forMyTickets: forMyTickets,
    );
  }
}
