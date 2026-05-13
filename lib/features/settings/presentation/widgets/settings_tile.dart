import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.label,
    required this.selected,
    required this.icon,
    required this.fontSize,
    required this.iconSize,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final IconData? icon;
  final double fontSize;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: iconSize,
                  color: selected
                      ? cs.onPrimary
                      : cs.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppFonts.roboto(
                  fontSize: fontSize,
                  height: 18 / 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? cs.onPrimary : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
