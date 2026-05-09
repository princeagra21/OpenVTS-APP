import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/file_picker_helper.dart';
import 'package:open_vts/features/support/support_models.dart';

class TicketAttachmentPicker extends StatelessWidget {
  const TicketAttachmentPicker({
    super.key,
    required this.attachments,
    required this.submitting,
    required this.role,
    required this.onPick,
    required this.onRemove,
  });

  final List<PickedFilePayload> attachments;
  final bool submitting;
  final SupportRole role;
  final VoidCallback onPick;
  final ValueChanged<PickedFilePayload> onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Attachments',
              style: AppFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: submitting ? null : onPick,
              icon: const Icon(Icons.attach_file),
              label: const Text('Add'),
            ),
          ],
        ),
        if (attachments.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: attachments.map((file) {
              return Chip(
                label: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 200,
                  ),
                  child: Text(
                    file.filename,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: submitting ? null : () => onRemove(file),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}