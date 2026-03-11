import 'package:fleet_stack/core/services/push_notifications_service.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PushNotificationBanner extends StatelessWidget {
  final PushDeviceState state;
  final bool loading;
  final VoidCallback onPressed;

  const PushNotificationBanner({
    super.key,
    required this.state,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!state.canShowBanner) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final bool enabled = state.registered;
    final String title = enabled
        ? 'Push notifications are on'
        : state.enabledByUser
        ? 'Reconnect push notifications'
        : 'Enable push notifications';
    final String subtitle = enabled
        ? 'This device will receive new alerts for this account.'
        : 'Turn on device notifications now. You can change this later here.';
    final String buttonLabel = enabled ? 'Turn off' : 'Enable';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              enabled
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_outlined,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: loading ? null : onPressed,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: loading
                  ? const AppShimmer(width: 58, height: 12, radius: 6)
                  : Text(
                      buttonLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
