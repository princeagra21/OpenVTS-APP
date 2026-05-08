import 'package:flutter/material.dart';

import '../theme/open_vts_colors.dart';
import '../theme/open_vts_spacing.dart';
import 'open_vts_button.dart';

class OpenVtsErrorState extends StatelessWidget {
  final String title;
  final String? description;
  final String retryLabel;
  final VoidCallback? onRetry;

  const OpenVtsErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.description,
    this.retryLabel = 'Try again',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(OpenVtsSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: OpenVtsColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: OpenVtsColors.danger.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.error_outline,
                color: OpenVtsColors.danger,
              ),
            ),
            const SizedBox(height: OpenVtsSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if ((description ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: OpenVtsSpacing.sm),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? OpenVtsColors.darkTextSecondary
                      : OpenVtsColors.textSecondary,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: OpenVtsSpacing.lg),
              OpenVtsButton(
                label: retryLabel,
                onPressed: onRetry,
                variant: OpenVtsButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
