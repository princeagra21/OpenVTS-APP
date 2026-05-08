import 'package:flutter/material.dart';

import '../theme/open_vts_theme.dart';

enum OpenVtsCardShadowLevel { none, subtle, medium, strong }

class OpenVtsCard extends StatelessWidget {
  const OpenVtsCard({
    super.key,
    required this.child,
    this.padding = OpenVtsSpacing.contentPadding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = OpenVtsRadius.radiusLg,
    this.shadowLevel = OpenVtsCardShadowLevel.subtle,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadius borderRadius;
  final OpenVtsCardShadowLevel shadowLevel;

  List<BoxShadow> _shadows() {
    switch (shadowLevel) {
      case OpenVtsCardShadowLevel.none:
        return OpenVtsShadows.none;
      case OpenVtsCardShadowLevel.subtle:
        return OpenVtsShadows.subtle;
      case OpenVtsCardShadowLevel.medium:
        return OpenVtsShadows.medium;
      case OpenVtsCardShadowLevel.strong:
        return OpenVtsShadows.strong;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? cs.surface,
        borderRadius: borderRadius,
        border: Border.all(
          color: borderColor ?? OpenVtsColors.border,
          width: 1,
        ),
        boxShadow: _shadows(),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return card;

    return Material(
      color: OpenVtsColors.transparent,
      child: InkWell(onTap: onTap, borderRadius: borderRadius, child: card),
    );
  }
}
