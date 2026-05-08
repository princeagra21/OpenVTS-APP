import 'package:flutter/material.dart';

import '../theme/open_vts_theme.dart';
import 'open_vts_text_field.dart';

class OpenVtsSearchField extends StatelessWidget {
  const OpenVtsSearchField({
    super.key,
    this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return OpenVtsTextField(
      controller: controller,
      hintText: hintText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      prefixIcon: Icon(
        Icons.search,
        size: OpenVtsIconSizes.md,
        color: OpenVtsColors.textTertiary,
      ),
      textInputAction: TextInputAction.search,
    );
  }
}
