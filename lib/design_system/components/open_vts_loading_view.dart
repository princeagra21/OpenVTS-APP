import 'package:flutter/material.dart';

import '../theme/open_vts_theme.dart';

class OpenVtsLoadingView extends StatelessWidget {
  const OpenVtsLoadingView({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
          if (label != null && label!.trim().isNotEmpty) ...[
            const SizedBox(height: OpenVtsSpacing.md),
            Text(
              label!,
              style: OpenVtsTypography.secondary(OpenVtsTypography.bodyMedium),
            ),
          ],
        ],
      ),
    );
  }
}
