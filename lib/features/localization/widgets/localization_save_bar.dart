import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/design_system/components/open_vts_button.dart';

class LocalizationSaveBar extends StatelessWidget {
  const LocalizationSaveBar({
    super.key,
    required this.title,
    required this.onReset,
    required this.onSave,
    required this.saving,
    required this.saveDisabled,
  });

  final String title;
  final VoidCallback onReset;
  final VoidCallback onSave;
  final bool saving;
  final bool saveDisabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppFonts.roboto(
            fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        Row(
          children: [
            SizedBox(
              width: 110,
              child: OpenVtsButton(
                label: 'Reset',
                variant: OpenVtsButtonVariant.secondary,
                onPressed: saving ? null : onReset,
                expand: false,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 96,
              child: OpenVtsButton(
                label: 'Save',
                onPressed: saveDisabled ? null : onSave,
                loading: saving,
                expand: false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
