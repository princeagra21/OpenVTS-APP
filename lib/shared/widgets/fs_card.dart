import 'package:flutter/material.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_card.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';

class FSCard extends StatelessWidget {
  const FSCard({
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.elevation,
    super.key,
  });

  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? elevation;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: padding ?? OpenVtsSpacing.contentPadding,
      onTap: onTap,
      backgroundColor: backgroundColor,
      shadowLevel: elevation == null || elevation == 0
          ? OpenVtsCardShadowLevel.none
          : OpenVtsCardShadowLevel.subtle,
      child: child,
    );
  }
}
