import 'package:flutter/material.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_text_field.dart';
import 'package:open_vts/core/theme/app_spacing.dart';
import 'package:open_vts/core/theme/app_text_styles.dart';
import 'package:open_vts/core/theme/app_colors.dart';

class FSTextField extends StatelessWidget {
  const FSTextField({
    required this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.controller,
    this.isPassword = false,
    this.isRequired = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixWidget,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    super.key,
  });

  final String label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final TextEditingController? controller;
  final bool isPassword;
  final bool isRequired;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: AppTextStyles.labelMedium.copyWith(color: Theme.of(context).colorScheme.onSurface),
            children: isRequired
                ? const [TextSpan(text: ' *', style: TextStyle(color: AppColors.danger))]
                : null,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        OpenVtsTextField(
          controller: controller,
          hintText: hint,
          errorText: errorText,
          obscureText: isPassword,
          keyboardType: keyboardType,
          prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
          suffixIcon: suffixWidget,
          validator: validator,
          onChanged: onChanged,
          maxLines: maxLines,
        ),
        if (helperText != null && errorText == null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(helperText!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ],
    );
  }
}
