import 'package:flutter/material.dart';

class TicketSubmitBar extends StatelessWidget {
  const TicketSubmitBar({
    super.key,
    required this.submitting,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool submitting;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: submitting ? null : onCancel,
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: submitting ? null : onSubmit,
            icon: submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.add),
            label: Text(
              submitting ? 'Submitting...' : 'Create Ticket',
            ),
          ),
        ),
      ],
    );
  }
}
