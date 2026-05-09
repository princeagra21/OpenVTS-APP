import 'package:flutter/material.dart';
import 'package:open_vts/features/support/support_models.dart';

class TicketMessageField extends StatelessWidget {
  const TicketMessageField({
    super.key,
    required this.controller,
    required this.role,
  });

  final TextEditingController controller;
  final SupportRole role;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 4,
      maxLines: 7,
      maxLength: role == SupportRole.superadmin ? 1000 : null,
      decoration: const InputDecoration(
        labelText: 'Message',
        hintText: 'Describe the issue in detail',
      ),
    );
  }
}