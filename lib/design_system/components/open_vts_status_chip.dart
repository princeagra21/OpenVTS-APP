import 'package:flutter/material.dart';

import '../theme/open_vts_theme.dart';

enum OpenVtsStatusTone { neutral, success, warning, danger, info }

class OpenVtsStatusChip extends StatelessWidget {
  const OpenVtsStatusChip({
    super.key,
    required this.label,
    this.tone = OpenVtsStatusTone.neutral,
    this.icon,
    this.padding,
    this.textStyle,
    this.compact = false,
  });

  final String label;
  final OpenVtsStatusTone tone;
  // Legacy optional leading icon support.
  final IconData? icon;
  // Legacy custom padding support.
  final EdgeInsetsGeometry? padding;
  // Legacy custom text style support.
  final TextStyle? textStyle;
  final bool compact;

  Color _background() {
    switch (tone) {
      case OpenVtsStatusTone.neutral:
        return OpenVtsColors.surface;
      case OpenVtsStatusTone.success:
        return OpenVtsColors.success.withOpacity(0.14);
      case OpenVtsStatusTone.warning:
        return OpenVtsColors.warning.withOpacity(0.16);
      case OpenVtsStatusTone.danger:
        return OpenVtsColors.danger.withOpacity(0.14);
      case OpenVtsStatusTone.info:
        return OpenVtsColors.brandInkSoft.withOpacity(0.14);
    }
  }

  Color _foreground() {
    switch (tone) {
      case OpenVtsStatusTone.neutral:
        return OpenVtsColors.textSecondary;
      case OpenVtsStatusTone.success:
        return OpenVtsColors.success;
      case OpenVtsStatusTone.warning:
        return OpenVtsColors.warning;
      case OpenVtsStatusTone.danger:
        return OpenVtsColors.danger;
      case OpenVtsStatusTone.info:
        return OpenVtsColors.brandInkSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsetsGeometry resolvedPadding =
        padding ??
        EdgeInsets.symmetric(
          horizontal: compact ? OpenVtsSpacing.sm : OpenVtsSpacing.md,
          vertical: compact ? OpenVtsSpacing.xs : OpenVtsSpacing.sm,
        );

    final Color foreground = _foreground();

    return Container(
      padding: resolvedPadding,
      decoration: BoxDecoration(
        color: _background(),
        borderRadius: OpenVtsRadius.radiusLg,
        border: Border.all(color: foreground.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 14, color: foreground),
          if (icon != null) const SizedBox(width: OpenVtsSpacing.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                textStyle ??
                OpenVtsTypography.labelLarge.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
