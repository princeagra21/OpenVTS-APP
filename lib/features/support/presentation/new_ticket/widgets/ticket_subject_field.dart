import 'package:flutter/material.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_text_field.dart';
import 'package:open_vts/features/support/domain/config/support_role_config.dart';

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
    return OpenVtsTextField(
      controller: controller,
      maxLength: role == SupportRole.superadmin ? 30 : 60,
      labelText: 'Title',
      hintText: 'Brief description of the issue',
    );
  }
}
