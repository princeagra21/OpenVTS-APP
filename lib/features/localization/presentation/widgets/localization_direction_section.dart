import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_card.dart';

class LocalizationDirectionSection extends StatelessWidget {
  const LocalizationDirectionSection({
    super.key,
    required this.textDirection,
    required this.onDirectionChanged,
  });

  final String textDirection;
  final ValueChanged<String> onDirectionChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DirectionHeader(),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _DirectionTile(
                    icon: Icons.format_textdirection_l_to_r,
                    label: 'LTR',
                    selected: textDirection == 'LTR',
                    onTap: () => onDirectionChanged('LTR'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DirectionTile(
                    icon: Icons.format_textdirection_r_to_l,
                    label: 'RTL',
                    selected: textDirection == 'RTL',
                    onTap: () => onDirectionChanged('RTL'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? colorScheme.surfaceContainerHighest
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.format_textdirection_l_to_r,
            color: colorScheme.onSurface,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Text Direction',
                style: AppFonts.roboto(
                  fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface.withValues(alpha: 0.87),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'LTR / RTL',
                style: AppFonts.roboto(
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DirectionTile extends StatelessWidget {
  const _DirectionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppFonts.roboto(
                color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
