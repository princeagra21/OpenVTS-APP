import 'package:flutter/material.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_button.dart';

class DocumentFormSubmitBar extends StatelessWidget {
  const DocumentFormSubmitBar({
    super.key,
    required this.isEdit,
    required this.submitting,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool isEdit;
  final bool submitting;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OpenVtsButton(
            label: 'Cancel',
            variant: OpenVtsButtonVariant.secondary,
            onPressed: onCancel,
            size: OpenVtsButtonSize.large,
            height: 50,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OpenVtsButton(
            label: isEdit ? 'Save' : 'Upload',
            onPressed: submitting ? null : onSubmit,
            loading: submitting,
            size: OpenVtsButtonSize.large,
            height: 50,
          ),
        ),
      ],
    );
  }
}
