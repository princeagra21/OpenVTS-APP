import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/design_system/components/open_vts_card.dart';

class LocalizationPreviewCard extends StatelessWidget {
  const LocalizationPreviewCard({
    super.key,
    required this.selectedLanguage,
    required this.textDirection,
    required this.timezone,
    required this.units,
    required this.lat,
    required this.lng,
    required this.zoom,
    required this.formattedDate,
    required this.formattedTime,
  });

  final String selectedLanguage;
  final String textDirection;
  final String timezone;
  final String units;
  final double lat;
  final double lng;
  final int zoom;
  final String formattedDate;
  final String formattedTime;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;

    return OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Preview',
                style: AppFonts.roboto(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) + 2,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              Flexible(
                child: Text(
                  'Lang: $selectedLanguage • Dir: $textDirection • TZ: $timezone',
                  style: AppFonts.roboto(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PreviewItem(label: 'Date', value: formattedDate),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PreviewItem(label: 'Time', value: formattedTime),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PreviewItem(
                  label: 'Map Center',
                  value: '$lat, $lng\nZoom $zoom',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PreviewItem(
                  label: 'Timezone',
                  value: timezone.isEmpty ? '—' : '$timezone\nUnits: $units',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewItem extends StatelessWidget {
  const _PreviewItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppFonts.roboto(
              fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.roboto(
              fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
