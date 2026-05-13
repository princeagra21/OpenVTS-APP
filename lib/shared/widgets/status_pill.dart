import 'package:flutter/material.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_components.dart';

class StatusPill extends StatelessWidget {
  final bool isActive;
  final String label;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const StatusPill({
    super.key,
    required this.isActive,
    required this.label,
    required this.fontSize,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return OpenVtsStatusChip(
      label: label,
      tone: isActive ? OpenVtsStatusTone.success : OpenVtsStatusTone.danger,
      icon: isActive ? Icons.check_circle : Icons.cancel,
      padding: padding,
      textStyle: (Theme.of(context).textTheme.labelMedium ?? const TextStyle())
          .copyWith(
            fontSize: fontSize,
            height: 14 / 11,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
