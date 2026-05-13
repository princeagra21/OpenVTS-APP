import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';

class DocumentVisibilityToggle extends StatelessWidget {
  const DocumentVisibilityToggle({
    super.key,
    required this.screenWidth,
    required this.value,
    required this.onChanged,
  });

  final double screenWidth;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          'Visible To Admin',
          style: AppFonts.roboto(
            fontSize: 12 * (screenWidth / 420).clamp(0.9, 1.0),
            height: 16 / 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const Spacer(),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
