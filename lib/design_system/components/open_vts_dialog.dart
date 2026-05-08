import 'package:flutter/material.dart';

import '../theme/open_vts_theme.dart';
import 'open_vts_button.dart';
import 'open_vts_card.dart';

class OpenVtsDialogAction {
  const OpenVtsDialogAction({
    required this.label,
    required this.onPressed,
    this.variant = OpenVtsButtonVariant.secondary,
  });

  final String label;
  final VoidCallback onPressed;
  final OpenVtsButtonVariant variant;
}

class OpenVtsDialog extends StatelessWidget {
  const OpenVtsDialog({
    super.key,
    required this.title,
    this.message,
    this.icon,
    required this.actions,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final List<OpenVtsDialogAction> actions;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? message,
    IconData? icon,
    required List<OpenVtsDialogAction> actions,
  }) {
    return showDialog<T>(
      context: context,
      builder: (_) => OpenVtsDialog(
        title: title,
        message: message,
        icon: icon,
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: OpenVtsColors.transparent,
      insetPadding: const EdgeInsets.all(OpenVtsSpacing.lg),
      child: OpenVtsCard(
        padding: const EdgeInsets.all(OpenVtsSpacing.lg),
        borderRadius: OpenVtsRadius.radiusXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.12),
                  borderRadius: OpenVtsRadius.radiusLg,
                ),
                child: Icon(icon, color: cs.primary, size: OpenVtsIconSizes.md),
              ),
              const SizedBox(height: OpenVtsSpacing.md),
            ],
            Text(
              title,
              style: OpenVtsTypography.primary(OpenVtsTypography.headingMedium),
            ),
            if (message != null && message!.trim().isNotEmpty) ...[
              const SizedBox(height: OpenVtsSpacing.sm),
              Text(
                message!,
                style: OpenVtsTypography.secondary(
                  OpenVtsTypography.bodyMedium,
                ),
              ),
            ],
            const SizedBox(height: OpenVtsSpacing.lg),
            Row(
              children: actions
                  .map(
                    (action) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          right: OpenVtsSpacing.sm,
                        ),
                        child: OpenVtsButton(
                          label: action.label,
                          onPressed: action.onPressed,
                          variant: action.variant,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}
