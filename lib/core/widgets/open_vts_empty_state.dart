import 'package:flutter/material.dart';

import '../theme/open_vts_colors.dart';
import '../theme/open_vts_spacing.dart';
import 'open_vts_button.dart';

class OpenVtsEmptyState extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const OpenVtsEmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark ? OpenVtsColors.darkSurface : OpenVtsColors.surface;
    final iconColor = isDark
        ? OpenVtsColors.darkTextSecondary
        : OpenVtsColors.textSecondary;

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
                color: iconBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? OpenVtsColors.darkBorder
                      : OpenVtsColors.border,
                ),
              ),
              child: Icon(icon, color: iconColor),
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
            if ((actionLabel ?? '').trim().isNotEmpty && onAction != null) ...[
              const SizedBox(height: OpenVtsSpacing.lg),
              OpenVtsButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: OpenVtsButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
