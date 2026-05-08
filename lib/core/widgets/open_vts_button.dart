import 'package:flutter/material.dart';

import '../theme/open_vts_colors.dart';
import '../theme/open_vts_radius.dart';
import '../theme/open_vts_spacing.dart';

enum OpenVtsButtonVariant { primary, secondary, ghost, danger }

class OpenVtsButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final OpenVtsButtonVariant variant;
  final bool loading;
  final IconData? leadingIcon;
  final bool expanded;
  final double? height;

  const OpenVtsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = OpenVtsButtonVariant.primary,
    this.loading = false,
    this.leadingIcon,
    this.expanded = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextStyle textStyle =
        Theme.of(context).textTheme.labelLarge ?? const TextStyle();
    final bool disabled = onPressed == null || loading;
    final double resolvedHeight = height ?? OpenVtsSpacing.buttonHeight;

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _foregroundColor(colorScheme),
              ),
            ),
          ),
        if (loading) const SizedBox(width: OpenVtsSpacing.sm),
        if (!loading && leadingIcon != null)
          Icon(leadingIcon, size: 18, color: _foregroundColor(colorScheme)),
        if (!loading && leadingIcon != null)
          const SizedBox(width: OpenVtsSpacing.sm),
        Text(
          label,
          style: textStyle.copyWith(color: _foregroundColor(colorScheme)),
        ),
      ],
    );

    final ButtonStyle baseStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, resolvedHeight)),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: OpenVtsRadius.radiusMd),
      ),
      side: WidgetStatePropertyAll(
        BorderSide(color: _borderColor(colorScheme)),
      ),
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return _backgroundColor(colorScheme).withValues(alpha: 0.6);
        }
        return _backgroundColor(colorScheme);
      }),
      foregroundColor: WidgetStatePropertyAll(_foregroundColor(colorScheme)),
      overlayColor: WidgetStatePropertyAll(
        _foregroundColor(colorScheme).withValues(alpha: 0.06),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: OpenVtsSpacing.lg),
      ),
    );

    final Widget button = switch (variant) {
      OpenVtsButtonVariant.primary => ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: baseStyle,
        child: content,
      ),
      OpenVtsButtonVariant.secondary => OutlinedButton(
        onPressed: disabled ? null : onPressed,
        style: baseStyle,
        child: content,
      ),
      OpenVtsButtonVariant.ghost => TextButton(
        onPressed: disabled ? null : onPressed,
        style: baseStyle.copyWith(
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          side: const WidgetStatePropertyAll(
            BorderSide(color: Colors.transparent),
          ),
        ),
        child: content,
      ),
      OpenVtsButtonVariant.danger => ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: baseStyle.copyWith(
          backgroundColor: WidgetStatePropertyAll(OpenVtsColors.danger),
          foregroundColor: const WidgetStatePropertyAll(OpenVtsColors.white),
          side: const WidgetStatePropertyAll(
            BorderSide(color: OpenVtsColors.danger),
          ),
          overlayColor: WidgetStatePropertyAll(
            OpenVtsColors.white.withValues(alpha: 0.08),
          ),
        ),
        child: content,
      ),
    };

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  Color _backgroundColor(ColorScheme scheme) {
    return switch (variant) {
      OpenVtsButtonVariant.primary => scheme.primary,
      OpenVtsButtonVariant.secondary => Colors.transparent,
      OpenVtsButtonVariant.ghost => Colors.transparent,
      OpenVtsButtonVariant.danger => OpenVtsColors.danger,
    };
  }

  Color _foregroundColor(ColorScheme scheme) {
    return switch (variant) {
      OpenVtsButtonVariant.primary => scheme.onPrimary,
      OpenVtsButtonVariant.secondary => scheme.onSurface,
      OpenVtsButtonVariant.ghost => scheme.primary,
      OpenVtsButtonVariant.danger => OpenVtsColors.white,
    };
  }

  Color _borderColor(ColorScheme scheme) {
    return switch (variant) {
      OpenVtsButtonVariant.primary => scheme.primary,
      OpenVtsButtonVariant.secondary => scheme.outline,
      OpenVtsButtonVariant.ghost => Colors.transparent,
      OpenVtsButtonVariant.danger => OpenVtsColors.danger,
    };
  }
}
