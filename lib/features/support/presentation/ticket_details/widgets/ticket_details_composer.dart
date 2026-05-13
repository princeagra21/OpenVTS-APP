import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/features/support/domain/config/support_role_config.dart';
import 'package:open_vts/features/support/presentation/ticket_details/ticket_details_controller.dart';
import 'package:open_vts/features/support/presentation/widgets/ticket_message_input.dart';

class TicketDetailsComposer extends StatelessWidget {
  const TicketDetailsComposer({
    super.key,
    required this.controller,
    required this.config,
    required this.onSend,
  });

  final TicketDetailsController controller;
  final SupportRoleConfig config;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        if (config.permissions.canAttachFiles) ...[
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: controller.state.sending ? null : controller.pickAttachment,
                icon: const Icon(Icons.attach_file),
                label: const Text('Attach file'),
              ),
              const SizedBox(width: 8),
              if (controller.state.attachment != null)
                Expanded(
                  child: Text(
                    controller.state.attachment!.filename,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.roboto(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                ),
              if (controller.state.attachment != null)
                IconButton(
                  onPressed: controller.state.sending
                      ? null
                      : () => controller.state.attachment = null,
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        TicketMessageInput(
          controller: controller.state.messageController,
          sending: controller.state.sending,
          enabled: !controller.state.loading,
          hintText:
              config.permissions.canSendInternalNotes &&
                  controller.state.selectedComposerTab == 'Internal Note'
              ? 'Type internal note...'
              : 'Type your reply...',
          onSend: onSend,
        ),
      ],
    );
  }
}
