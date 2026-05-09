import 'package:flutter/material.dart';
import 'package:open_vts/design_system/components/open_vts_text_field.dart';
import 'package:open_vts/features/support/support_role_config.dart';

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
    return OpenVtsTextField(
      controller: controller,
      minLines: 4,
      maxLines: 7,
      maxLength: role == SupportRole.superadmin ? 1000 : null,
      labelText: 'Message',
      hintText: 'Describe the issue in detail',
    );
  }
}
