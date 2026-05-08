import 'package:flutter/material.dart';

import '../theme/open_vts_colors.dart';
import '../theme/open_vts_radius.dart';
import '../theme/open_vts_spacing.dart';

class OpenVtsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final BorderRadius borderRadius;

  const OpenVtsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(OpenVtsSpacing.cardPadding),
    this.margin = const EdgeInsets.all(0),
    this.onTap,
    this.backgroundColor,
    this.borderRadius = OpenVtsRadius.radiusLg,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color resolvedBackground = backgroundColor ?? colorScheme.surface;
    final Color borderColor = Theme.of(context).brightness == Brightness.dark
        ? OpenVtsColors.darkBorder
        : OpenVtsColors.border;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
