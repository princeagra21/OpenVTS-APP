import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_button.dart';

class SettingsProfileActions extends StatelessWidget {
  const SettingsProfileActions({
    super.key,
    required this.onEdit,
    required this.onPassword,
  });

  final VoidCallback onEdit;
  final VoidCallback onPassword;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final titleSize = AdaptiveUtils.getSubtitleFontSize(width) + 2;
    final subtitleSize = AdaptiveUtils.getTitleFontSize(width) + 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;

        final actionButtons = compact
            ? Column(
                children: [
                  OpenVtsButton(
                    label: 'Edit',
                    onPressed: onEdit,
                    leading: Icons.edit_outlined,
                    size: OpenVtsButtonSize.small,
                  ),
                  const SizedBox(height: 8),
                  OpenVtsButton(
                    label: 'Password',
                    onPressed: onPassword,
                    leading: Icons.lock_outline,
                    variant: OpenVtsButtonVariant.secondary,
                    size: OpenVtsButtonSize.small,
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 110,
                    child: OpenVtsButton(
                      label: 'Edit',
                      onPressed: onEdit,
                      leading: Icons.edit_outlined,
                      size: OpenVtsButtonSize.small,
                      expand: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 132,
                    child: OpenVtsButton(
                      label: 'Password',
                      onPressed: onPassword,
                      leading: Icons.lock_outline,
                      variant: OpenVtsButtonVariant.secondary,
                      size: OpenVtsButtonSize.small,
                      expand: false,
                    ),
                  ),
                ],
              );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview',
                style: AppFonts.roboto(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Profile',
                style: AppFonts.roboto(
                  fontSize: subtitleSize,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 12),
              actionButtons,
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overview',
                    style: AppFonts.roboto(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Profile',
                    style: AppFonts.roboto(
                      fontSize: subtitleSize,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            actionButtons,
          ],
        );
      },
    );
  }
}
