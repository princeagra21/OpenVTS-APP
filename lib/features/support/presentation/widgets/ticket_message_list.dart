import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/features/support/domain/entities/support_models.dart';

class TicketMessageList extends StatelessWidget {
  const TicketMessageList({
    super.key,
    required this.messages,
    this.onAttachmentTap,
  });

  final List<SupportTicketMessage> messages;
  final ValueChanged<SupportTicketMessage>? onAttachmentTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet',
          style: AppFonts.roboto(
            fontSize: 13,
            color: cs.onSurface.withValues(alpha: 0.65),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isInternal = msg.isInternal;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isInternal
                ? Colors.orange.withValues(alpha: 0.1)
                : cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isInternal
                  ? Colors.orange.withValues(alpha: 0.35)
                  : cs.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                msg.senderName.isEmpty ? 'Unknown' : msg.senderName,
                style: AppFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                msg.message,
                style: AppFonts.roboto(fontSize: 13, color: cs.onSurface),
              ),
              if (msg.attachmentName.isNotEmpty) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: onAttachmentTap == null
                      ? null
                      : () => onAttachmentTap!(msg),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      msg.attachmentName,
                      style: AppFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
