import 'package:flutter/material.dart';
import 'package:open_vts/features/support/support_role_config.dart';
import 'package:open_vts/features/support/ticket_details/ticket_details_controller.dart';

class TicketDetailsStatusUpdater extends StatelessWidget {
  const TicketDetailsStatusUpdater({
    super.key,
    required this.controller,
    required this.config,
    required this.onStatusChanged,
  });

  final TicketDetailsController controller;
  final SupportRoleConfig config;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    if (!config.permissions.canUpdateStatus) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: controller.state.selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Ticket Status',
            ),
            items: controller.statusOptions
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  ),
                )
                .toList(),
            onChanged: controller.state.updatingStatus
                ? null
                : (value) {
                    if (value == null) return;
                    onStatusChanged(value);
                  },
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: controller.state.updatingStatus ? null : () => controller.updateStatus(context),
          icon: controller.state.updatingStatus
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Update'),
        ),
      ],
    );
  }
}