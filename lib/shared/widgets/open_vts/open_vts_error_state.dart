import 'package:flutter/material.dart';

import 'package:open_vts/core/theme/open_vts_theme.dart';
import 'open_vts_button.dart';
import 'open_vts_card.dart';

class OpenVtsErrorState extends StatelessWidget {
  const OpenVtsErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    this.description,
    this.retryLabel = 'Try again',
    this.onRetry,
  });

  final String title;
  final String? message;
  // Legacy alias used by core widget API.
  final String? description;
  // Legacy retry button label.
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final String? resolvedMessage =
        (message ?? description)?.trim().isNotEmpty == true
        ? (message ?? description)!.trim()
        : null;

    return OpenVtsCard(
      borderColor: OpenVtsColors.danger.withOpacity(0.25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: OpenVtsIconSizes.xxl,
            color: OpenVtsColors.danger,
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: OpenVtsTypography.primary(OpenVtsTypography.headingMedium),
          ),
          if (resolvedMessage != null) ...[
            const SizedBox(height: OpenVtsSpacing.xs),
            Text(
              resolvedMessage,
              textAlign: TextAlign.center,
              style: OpenVtsTypography.secondary(OpenVtsTypography.bodyMedium),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: OpenVtsSpacing.lg),
            OpenVtsButton(
              label: retryLabel,
              onPressed: onRetry,
              variant: OpenVtsButtonVariant.danger,
            ),
          ],
        ],
      ),
    );
  }
}
