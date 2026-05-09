import 'package:flutter/material.dart';
import 'package:open_vts/features/support/ticket_details/ticket_details_controller.dart';
import 'package:open_vts/features/support/widgets/ticket_empty_state.dart';
import 'package:open_vts/features/support/widgets/ticket_message_list.dart';

class TicketDetailsMessages extends StatelessWidget {
  const TicketDetailsMessages({
    super.key,
    required this.controller,
    required this.onRetry,
  });

  final TicketDetailsController controller;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (controller.state.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (controller.state.errorMessage != null && controller.state.messages.isEmpty) {
      return TicketEmptyState(
        message: controller.state.errorMessage!,
        action: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      );
    } else {
      return Container(
        height: 360,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.outline.withValues(alpha: 0.2),
          ),
        ),
        child: TicketMessageList(
          messages: controller.visibleMessages,
          onAttachmentTap: (message) => controller.openAttachment(context, message),
        ),
      );
    }
  }
}