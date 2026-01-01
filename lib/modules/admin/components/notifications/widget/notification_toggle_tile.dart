// components/notifications/widget/notification_toggle_tile.dart
import 'package:flutter/material.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';

class NotificationToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const NotificationToggleTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final cs = Theme.of(context).colorScheme;

    final iconSize = AdaptiveUtils.getIconSize(width);
    final titleSize = AdaptiveUtils.getSubtitleFontSize(width) - 2;
    final subtitleSize = AdaptiveUtils.getTitleFontSize(width);
    final horizontal = AdaptiveUtils.getHorizontalPadding(width);
    final vertPadding = AdaptiveUtils.isVerySmallScreen(width) ? 8.0 : 10.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertPadding),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: iconSize, color: cs.primary),
          SizedBox(width: AdaptiveUtils.getIconPaddingLeft(width)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: subtitleSize,
                    color: cs.onSurface.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: cs.primary,
          ),
        ],
      ),
    );
  }
}
