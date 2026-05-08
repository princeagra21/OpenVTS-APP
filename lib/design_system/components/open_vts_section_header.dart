import 'package:flutter/material.dart';

import '../theme/open_vts_theme.dart';

class OpenVtsSectionHeader extends StatelessWidget {
  const OpenVtsSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ??
          const EdgeInsets.symmetric(
            horizontal: OpenVtsSpacing.xs,
            vertical: OpenVtsSpacing.sm,
          ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: OpenVtsTypography.primary(
                    OpenVtsTypography.headingMedium,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: OpenVtsSpacing.xs),
                  Text(
                    subtitle!,
                    style: OpenVtsTypography.secondary(
                      OpenVtsTypography.bodyMedium,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
