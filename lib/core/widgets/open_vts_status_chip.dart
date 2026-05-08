import 'package:flutter/material.dart';

import '../theme/open_vts_colors.dart';
import '../theme/open_vts_radius.dart';
import '../theme/open_vts_spacing.dart';

enum OpenVtsStatusTone { neutral, success, warning, danger }

class OpenVtsStatusChip extends StatelessWidget {
  final String label;
  final OpenVtsStatusTone tone;
  final IconData? icon;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;

  const OpenVtsStatusChip({
    super.key,
    required this.label,
    this.tone = OpenVtsStatusTone.neutral,
    this.icon,
    this.padding = const EdgeInsets.symmetric(
      horizontal: OpenVtsSpacing.md,
      vertical: OpenVtsSpacing.xs,
    ),
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = _foreground(isDark);
    final Color bg = _background(isDark);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(
          Radius.circular(OpenVtsRadius.pill),
        ),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 14, color: fg),
          if (icon != null) const SizedBox(width: OpenVtsSpacing.xs),
          Text(
            label,
            style:
                textStyle ??
                (Theme.of(context).textTheme.labelMedium ?? const TextStyle())
                    .copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Color _foreground(bool isDark) {
    return switch (tone) {
      OpenVtsStatusTone.neutral =>
        isDark ? OpenVtsColors.darkTextPrimary : OpenVtsColors.textPrimary,
      OpenVtsStatusTone.success => OpenVtsColors.success,
      OpenVtsStatusTone.warning => OpenVtsColors.warning,
      OpenVtsStatusTone.danger => OpenVtsColors.danger,
    };
  }

  Color _background(bool isDark) {
    final Color base = isDark
        ? OpenVtsColors.darkSurface
        : OpenVtsColors.surface;
    return switch (tone) {
      OpenVtsStatusTone.neutral => base,
      OpenVtsStatusTone.success => OpenVtsColors.success.withValues(alpha: 0.1),
      OpenVtsStatusTone.warning => OpenVtsColors.warning.withValues(alpha: 0.1),
      OpenVtsStatusTone.danger => OpenVtsColors.danger.withValues(alpha: 0.1),
    };
  }
}
