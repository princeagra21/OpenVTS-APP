// lib/screens/notification_toggle_tile.dart
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // If using GoogleFonts, else adjust

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
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double subtitleFont = AdaptiveUtils.getSubtitleFontSize(width) - 1;
    final double bodyFont = AdaptiveUtils.getTitleFontSize(width) - 1;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        size: AdaptiveUtils.getIconSize(width),
        color: colorScheme.primary,
      ),
      title: Text(
        title,
        style: GoogleFonts.inter( // Adjust if not using GoogleFonts
          fontSize: subtitleFont,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: bodyFont,
          color: colorScheme.onSurface.withOpacity(0.55),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: colorScheme.primary,
      ),
    );
  }
}