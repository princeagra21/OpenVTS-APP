import 'package:open_vts/core/services/push_notifications_service.dart';
import 'package:open_vts/core/theme/open_vts_spacing.dart';
import 'package:flutter/material.dart';

import 'open_vts_button.dart';
import 'open_vts_card.dart';

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
    final textTheme = Theme.of(context).textTheme;

    return OpenVtsCard(
      margin: const EdgeInsets.only(bottom: OpenVtsSpacing.lg),
      padding: const EdgeInsets.all(OpenVtsSpacing.lg),
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
          const SizedBox(width: OpenVtsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: OpenVtsSpacing.xs),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.md),
          OpenVtsButton(
            label: buttonLabel,
            onPressed: loading ? null : onPressed,
            loading: loading,
            height: 36,
            variant: enabled
                ? OpenVtsButtonVariant.ghost
                : OpenVtsButtonVariant.secondary,
          ),
        ],
      ),
    );
  }
}
