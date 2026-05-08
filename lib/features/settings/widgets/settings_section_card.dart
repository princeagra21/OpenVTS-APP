import 'package:flutter/material.dart';
import 'package:open_vts/design_system/components/open_vts_card.dart';

class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return OpenVtsCard(
      padding: padding,
      borderRadius: BorderRadius.circular(16),
      borderColor: colorScheme.onSurface.withValues(alpha: 0.1),
      shadowLevel: OpenVtsCardShadowLevel.subtle,
      child: child,
    );
  }
}
