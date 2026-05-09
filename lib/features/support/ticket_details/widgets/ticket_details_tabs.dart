import 'package:flutter/material.dart';
import 'package:open_vts/features/support/support_role_config.dart';
import 'package:open_vts/features/support/ticket_details/ticket_details_state.dart';

class TicketDetailsTabs extends StatelessWidget {
  const TicketDetailsTabs({
    super.key,
    required this.config,
    required this.state,
    required this.onTabChanged,
  });

  final SupportRoleConfig config;
  final TicketDetailsState state;
  final ValueChanged<String> onTabChanged;

  @override
  Widget build(BuildContext context) {
    if (!config.permissions.canSendInternalNotes) return const SizedBox.shrink();

    return Row(
      children: [
        ChoiceChip(
          label: const Text('Conversation'),
          selected: state.selectedComposerTab == 'Conversation',
          onSelected: (_) => onTabChanged('Conversation'),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('Internal Note'),
          selected: state.selectedComposerTab == 'Internal Note',
          onSelected: (_) => onTabChanged('Internal Note'),
        ),
      ],
    );
  }
}