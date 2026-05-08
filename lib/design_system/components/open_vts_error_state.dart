import 'package:flutter/material.dart';

import '../theme/open_vts_theme.dart';
import 'open_vts_button.dart';
import 'open_vts_card.dart';

class OpenVtsErrorState extends StatelessWidget {
  const OpenVtsErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: OpenVtsTypography.secondary(OpenVtsTypography.bodyMedium),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: OpenVtsSpacing.lg),
            OpenVtsButton(
              label: 'Retry',
              onPressed: onRetry,
              variant: OpenVtsButtonVariant.danger,
            ),
          ],
        ],
      ),
    );
  }
}
