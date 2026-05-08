import 'package:flutter/material.dart';
import 'package:open_vts/core/models/user_notification_preferences.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/modules/user/screens/notification/push_notification/widgets/channel_row.dart';

class PushNotificationChannelSection extends StatelessWidget {
  const PushNotificationChannelSection({
    super.key,
    required this.title,
    required this.preference,
    required this.padding,
    required this.onToggleMobile,
    required this.onToggleWhatsApp,
    required this.onToggleEmail,
  });

  final String title;
  final UserNotificationPreferenceItem preference;
  final double padding;
  final VoidCallback onToggleMobile;
  final VoidCallback onToggleWhatsApp;
  final VoidCallback onToggleEmail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppFonts.roboto(
              fontSize: AdaptiveUtils.getSubtitleFontSize(width),
              height: 24 / 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          PushNotificationChannelRow(
            label: 'Mobile Push',
            icon: Icons.notifications_active_outlined,
            enabled: preference.notifyMobilePush,
            onTap: onToggleMobile,
          ),
          const SizedBox(height: 12),
          PushNotificationChannelRow(
            label: 'WhatsApp',
            icon: Icons.chat_bubble_outline,
            enabled: preference.notifyWhatsapp,
            onTap: onToggleWhatsApp,
          ),
          const SizedBox(height: 12),
          PushNotificationChannelRow(
            label: 'Email',
            icon: Icons.email_outlined,
            enabled: preference.notifyEmail,
            onTap: onToggleEmail,
          ),
        ],
      ),
    );
  }
}

