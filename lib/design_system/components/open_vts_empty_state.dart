import 'package:flutter/material.dart';

import '../theme/open_vts_theme.dart';
import 'open_vts_button.dart';
import 'open_vts_card.dart';

class OpenVtsEmptyState extends StatelessWidget {
  const OpenVtsEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return OpenVtsCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: OpenVtsIconSizes.xxl,
            color: cs.primary.withOpacity(0.8),
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: OpenVtsTypography.primary(OpenVtsTypography.headingMedium),
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: OpenVtsTypography.secondary(OpenVtsTypography.bodyMedium),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: OpenVtsSpacing.lg),
            OpenVtsButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}
