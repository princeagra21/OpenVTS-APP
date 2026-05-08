import 'package:flutter/material.dart';

import '../theme/open_vts_theme.dart';

class OpenVtsLoadingView extends StatelessWidget {
  const OpenVtsLoadingView({
    super.key,
    this.label,
    this.message,
    this.size = 24,
  });

  final String? label;
  // Legacy alias used by core widget API.
  final String? message;
  // Legacy explicit spinner size support.
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final String? resolvedLabel = label ?? message;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
          if (resolvedLabel != null && resolvedLabel.trim().isNotEmpty) ...[
            const SizedBox(height: OpenVtsSpacing.md),
            Text(
              resolvedLabel,
              style: OpenVtsTypography.secondary(OpenVtsTypography.bodyMedium),
            ),
          ],
        ],
      ),
    );
  }
}
