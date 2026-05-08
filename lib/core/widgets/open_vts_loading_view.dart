import 'package:flutter/material.dart';

import '../theme/open_vts_colors.dart';
import '../theme/open_vts_spacing.dart';

class OpenVtsLoadingView extends StatelessWidget {
  final String? message;
  final double size;

  const OpenVtsLoadingView({super.key, this.message, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color secondary = isDark
        ? OpenVtsColors.darkTextSecondary
        : OpenVtsColors.textSecondary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          if ((message ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: OpenVtsSpacing.md),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: secondary),
            ),
          ],
        ],
      ),
    );
  }
}
