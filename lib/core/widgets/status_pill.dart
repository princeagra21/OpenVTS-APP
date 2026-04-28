import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillColor = isDark
        ? (isActive
            ? colorScheme.primary.withOpacity(0.15)
            : colorScheme.error.withOpacity(0.15))
        : Colors.grey.shade50;
    final fgColor = isDark
        ? (isActive ? colorScheme.primary : colorScheme.error)
        : colorScheme.onSurface;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: pillColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            size: fontSize + 2,
            color: fgColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: fontSize,
              height: 14 / 11,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
            softWrap: true,
          ),
        ],
      ),
    );
  }
}
