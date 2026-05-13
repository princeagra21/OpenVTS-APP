import 'package:flutter/material.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_button.dart';

enum FSButtonVariant { primary, secondary, outlined, ghost, danger }
enum FSButtonSize { sm, md, lg }

class FSButton extends StatelessWidget {
  const FSButton({
    required this.label,
    this.onPressed,
    this.variant = FSButtonVariant.primary,
    this.size = FSButtonSize.md,
    this.leadingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final FSButtonVariant variant;
  final FSButtonSize size;
  final IconData? leadingIcon;
  final bool isLoading;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    return OpenVtsButton(
      label: label,
      onPressed: onPressed,
      loading: isLoading,
      leading: leadingIcon,
      expand: isFullWidth,
      variant: switch (variant) {
        FSButtonVariant.primary => OpenVtsButtonVariant.primary,
        FSButtonVariant.secondary || FSButtonVariant.outlined => OpenVtsButtonVariant.secondary,
        FSButtonVariant.ghost => OpenVtsButtonVariant.ghost,
        FSButtonVariant.danger => OpenVtsButtonVariant.danger,
      },
      size: switch (size) {
        FSButtonSize.sm => OpenVtsButtonSize.small,
        FSButtonSize.md => OpenVtsButtonSize.medium,
        FSButtonSize.lg => OpenVtsButtonSize.large,
      },
    );
  }
}
