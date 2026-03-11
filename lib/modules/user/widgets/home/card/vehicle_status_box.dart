import 'package:fleet_stack/core/models/user_fleet_status_summary.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleStatusBox extends StatelessWidget {
  final bool loading;
  final UserFleetStatusSummary? summary;

  const VehicleStatusBox({
    super.key,
    required this.loading,
    required this.summary,
  });

  Map<String, dynamic> getStatusMeta(String label) {
    final key = label.toLowerCase();
    if (key.startsWith('running')) {
      return {'color': Colors.green, 'icon': Icons.check};
    }
    if (key.startsWith('idle')) {
      return {'color': Colors.orangeAccent, 'icon': Icons.pause_rounded};
    }
    if (key.startsWith('stopped')) {
      return {
        'color': Colors.yellow[700]!,
        'icon': Icons.warning_amber_rounded,
      };
    }
    if (key.startsWith('inactive')) {
      return {'color': Colors.redAccent, 'icon': Icons.error_outline};
    }
    return {'color': Colors.grey[400]!, 'icon': null};
  }

  List<_StatusRow> _rows() {
    return [
      _StatusRow(
        label: 'Running',
        count: summary?.running,
        percent: summary?.percentFor('running'),
      ),
      _StatusRow(
        label: 'Idle',
        count: summary?.idle,
        percent: summary?.percentFor('idle'),
      ),
      _StatusRow(
        label: 'Stopped',
        count: summary?.stopped,
        percent: summary?.percentFor('stopped'),
      ),
      _StatusRow(
        label: 'Inactive',
        count: summary?.inactive,
        percent: summary?.percentFor('inactive'),
      ),
      _StatusRow(
        label: 'No Data',
        count: summary?.noData,
        percent: summary?.percentFor('noData'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth);
    final descriptionFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final legendFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) + 1;
    final spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth);
    final rows = _rows();

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.2,
                backgroundColor: colorScheme.surfaceVariant,
                child: Icon(Icons.directions_car, color: colorScheme.primary),
              ),
              SizedBox(width: padding),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vehicle Status',
                    style: GoogleFonts.inter(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: spacing / 2),
                  Text(
                    'Live distribution',
                    style: GoogleFonts.inter(
                      fontSize: descriptionFontSize,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: spacing + 6),
          Column(
            children: rows.map((data) {
              final meta = getStatusMeta(data.label);
              final dotColor = meta['color'] as Color;
              final innerIcon = meta['icon'] as IconData?;
              const bulletSize = 18.0;
              const innerIconSize = 12.0;
              final percent = data.percent;
              final percentText = percent == null
                  ? null
                  : '(${percent.toStringAsFixed(1)}%)';

              return Padding(
                padding: EdgeInsets.symmetric(vertical: spacing / 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: bulletSize,
                      height: bulletSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                      ),
                      child: innerIcon != null
                          ? Center(
                              child: Icon(
                                innerIcon,
                                size: innerIconSize,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: Text(
                        data.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: legendFontSize,
                          color: colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (loading)
                          AppShimmer(
                            width: 42,
                            height: legendFontSize + 6,
                            radius: 10,
                          )
                        else
                          Text(
                            data.count?.toString() ?? '—',
                            style: GoogleFonts.inter(
                              fontSize: legendFontSize,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        if (loading) ...[
                          const SizedBox(height: 4),
                          AppShimmer(
                            width: 54,
                            height: legendFontSize + 2,
                            radius: 10,
                          ),
                        ] else if (percentText != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            percentText,
                            style: GoogleFonts.inter(
                              fontSize: legendFontSize,
                              fontWeight: FontWeight.w600,
                              color: dotColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          SizedBox(height: padding),
        ],
      ),
    );
  }
}

class _StatusRow {
  final String label;
  final int? count;
  final double? percent;

  const _StatusRow({
    required this.label,
    required this.count,
    required this.percent,
  });
}
