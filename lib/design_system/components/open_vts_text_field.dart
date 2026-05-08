import 'package:flutter/material.dart';

import '../theme/open_vts_theme.dart';

class OpenVtsTextField extends StatelessWidget {
  const OpenVtsTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.labelText,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.onTap,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.validator,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  // Legacy alias for labelText.
  final String? label;
  final String? labelText;
  final String? hintText;
  // Legacy explicit error text override.
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  // Legacy callback hook used by old core widget.
  final VoidCallback? onEditingComplete;
  final VoidCallback? onTap;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  // Legacy validator support.
  final FormFieldValidator<String>? validator;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final String? resolvedLabel = labelText ?? label;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onEditingComplete: onEditingComplete,
      onTap: onTap,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      autofillHints: autofillHints,
      textCapitalization: textCapitalization,
      style: OpenVtsTypography.primary(OpenVtsTypography.bodyLarge),
      decoration: InputDecoration(
        labelText: resolvedLabel,
        hintText: hintText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: cs.surface,
        contentPadding: OpenVtsSpacing.fieldContentPadding,
        enabledBorder: OpenVtsBorders.input(color: OpenVtsColors.border),
        focusedBorder: OpenVtsBorders.input(color: cs.primary, width: 1.5),
        disabledBorder: OpenVtsBorders.input(
          color: OpenVtsColors.border.withOpacity(0.5),
        ),
      ),
    );
  }
}
