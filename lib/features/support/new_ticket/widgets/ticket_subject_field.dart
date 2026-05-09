import 'package:flutter/material.dart';
import 'package:open_vts/features/support/support_models.dart';

class TicketSubjectField extends StatelessWidget {
  const TicketSubjectField({
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
      maxLength: role == SupportRole.superadmin ? 30 : 60,
      decoration: const InputDecoration(
        labelText: 'Title',
        hintText: 'Brief description of the issue',
      ),
    );
  }
}