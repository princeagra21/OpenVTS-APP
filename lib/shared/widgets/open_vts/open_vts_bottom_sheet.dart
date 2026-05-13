import 'package:flutter/material.dart';

import 'package:open_vts/core/theme/open_vts_theme.dart';

class OpenVtsBottomSheet extends StatelessWidget {
  const OpenVtsBottomSheet({super.key, required this.child, this.title});

  final Widget child;
  final String? title;

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: OpenVtsColors.transparent,
      builder: (_) => OpenVtsBottomSheet(title: title, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(OpenVtsRadius.xl),
          ),
          border: Border(
            top: BorderSide(color: OpenVtsColors.border, width: 1),
          ),
          boxShadow: OpenVtsShadows.medium,
        ),
        padding: const EdgeInsets.fromLTRB(
          OpenVtsSpacing.lg,
          OpenVtsSpacing.md,
          OpenVtsSpacing.lg,
          OpenVtsSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: OpenVtsColors.divider,
                  borderRadius: OpenVtsRadius.radiusLg,
                ),
              ),
            ),
            if (title != null && title!.trim().isNotEmpty) ...[
              const SizedBox(height: OpenVtsSpacing.md),
              Text(
                title!,
                style: OpenVtsTypography.primary(
                  OpenVtsTypography.headingMedium,
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
