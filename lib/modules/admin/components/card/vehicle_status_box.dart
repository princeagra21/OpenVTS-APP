// components/charts/vehicle_status_box.dart
import 'package:fleet_stack/core/models/admin_dashboard_summary.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/adaptive_utils.dart';

class VehicleStatusBox extends StatelessWidget {
  final AdminDashboardSummary? summary;
  final bool loading;

  const VehicleStatusBox({super.key, this.summary, this.loading = false});

  Map<String, dynamic> getStatusMeta(String label) {
    final key = label.toLowerCase();
    if (key.startsWith('running')) {
      return {'color': Colors.green, 'icon': Icons.check};
    } else if (key.startsWith('stop')) {
      return {
        'color': Colors.yellow[700]!,
        'icon': Icons.warning_amber_rounded,
      };
    } else if (key.contains('not work') || key.contains('not working')) {
      return {'color': Colors.redAccent, 'icon': Icons.error_outline};
    } else if (key.contains('no data')) {
      return {'color': Colors.grey[400]!, 'icon': null};
    } else {
      return {'color': Colors.grey[400]!, 'icon': null};
    }
  }

  String _formatCount(int value) {
    final text = value.toString();
    return text.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth);
    final double descriptionFontSize = AdaptiveUtils.getTitleFontSize(
      screenWidth,
    );
    final double legendFontSize =
        AdaptiveUtils.getTitleFontSize(screenWidth) + 1;
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth);

    final statusRows = <({String label, int value})>[
      (label: 'Running', value: summary?.running ?? 0),
      (label: 'Stop', value: summary?.stop ?? 0),
      (label: 'Not Working (48h)', value: summary?.notWorking48h ?? 0),
      (label: 'No Data', value: summary?.noData ?? 0),
    ];

    final total = statusRows.fold<int>(0, (acc, row) => acc + row.value);

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
                  loading
                      ? AppShimmer(
                          width: screenWidth * 0.34,
                          height: titleFontSize + 6,
                          radius: 8,
                        )
                      : Text(
                          'Vehicle Status',
                          style: GoogleFonts.inter(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                  SizedBox(height: spacing / 2),
                  loading
                      ? AppShimmer(
                          width: screenWidth * 0.30,
                          height: descriptionFontSize + 4,
                          radius: 8,
                        )
                      : Text(
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
            children: statusRows.map((data) {
              final meta = getStatusMeta(data.label);
              final Color dotColor = meta['color'] as Color;
              final IconData? innerIcon = meta['icon'] as IconData?;

              const double bulletSize = 18.0;
              const double innerIconSize = 12.0;

              final countText = summary == null
                  ? '—'
                  : _formatCount(data.value);
              final percentText = (summary == null || total <= 0)
                  ? '—'
                  : '(${((data.value * 100) / total).toStringAsFixed(1)}%)';

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
                      child: loading
                          ? AppShimmer(
                              width: screenWidth * 0.32,
                              height: legendFontSize + 4,
                              radius: 7,
                            )
                          : Text(
                              data.label,
                              style: GoogleFonts.inter(
                                fontSize: legendFontSize,
                                color: colorScheme.onSurface.withOpacity(0.87),
                              ),
                            ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        loading
                            ? AppShimmer(
                                width: screenWidth * 0.16,
                                height: legendFontSize + 6,
                                radius: 7,
                              )
                            : Text(
                                countText,
                                style: GoogleFonts.inter(
                                  fontSize: legendFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                        SizedBox(height: 4),
                        loading
                            ? AppShimmer(
                                width: screenWidth * 0.13,
                                height: legendFontSize + 4,
                                radius: 7,
                              )
                            : Text(
                                percentText,
                                style: GoogleFonts.inter(
                                  fontSize: legendFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: dotColor,
                                ),
                              ),
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
