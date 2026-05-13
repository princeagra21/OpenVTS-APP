import 'package:flutter/material.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_button.dart';

class TicketMessageInput extends StatelessWidget {
  const TicketMessageInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.enabled = true,
    this.sending = false,
    this.hintText = 'Type your reply...',
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;
  final bool sending;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled && !sending,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                isDense: true,
              ),
              minLines: 1,
              maxLines: 4,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: OpenVtsButton(
              label: 'Send',
              leadingIcon: Icons.send,
              onPressed: enabled && !sending ? onSend : null,
              loading: sending,
              expand: false,
            ),
          ),
        ],
      ),
    );
  }
}
