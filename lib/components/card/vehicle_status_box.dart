// components/charts/vehicle_status_box.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/adaptive_utils.dart';

class VehicleStatusBox extends StatefulWidget {
  const VehicleStatusBox({super.key});

  @override
  State<VehicleStatusBox> createState() => _VehicleStatusBoxState();
}

class _VehicleStatusBoxState extends State<VehicleStatusBox> {
  int? touchedIndex;

  final List<Map<String, dynamic>> statusData = [
    {"label": "Running",           "count": "2,986", "percent": 26.6},
    {"label": "Stop",              "count": "111",   "percent": 0.99},
    {"label": "Not Working (48h)", "count": "7,194", "percent": 64.08},
    {"label": "No Data",           "count": "935",   "percent": 8.33},
  ];

  final List<Color> colors = [
    Colors.black,
    Colors.black.withOpacity(0.7),
    Colors.black.withOpacity(0.4),
    Colors.black.withOpacity(0.1),
  ];

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    // All sizes from our shared AdaptiveUtils
    final double padding         = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double titleFontSize   = AdaptiveUtils.getSubtitleFontSize(screenWidth);     // 14–18
    final double legendFontSize  = AdaptiveUtils.getTitleFontSize(screenWidth) + 1;    // 12–14
    final double chartHeight     = AdaptiveUtils.isVerySmallScreen(screenWidth)
        ? 180 : AdaptiveUtils.isSmallScreen(screenWidth) ? 200 : 220;

    // Touch feedback scaling
    final double baseRadius      = AdaptiveUtils.getButtonSize(screenWidth) + 34; // ~62–70
    final double touchedRadius   = baseRadius + 20;
    final double centerRadius    = AdaptiveUtils.getIconSize(screenWidth) + 14;     // ~30–34

    final double touchedFontSize = titleFontSize;
    final double normalFontSize  = AdaptiveUtils.getTitleFontSize(screenWidth);     // 11–13

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
          // Header: Icon + Title
          Row(
            children: [
              CircleAvatar(
                radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.2,
                backgroundColor: Colors.grey[200],
                child: const Icon(Icons.directions_car, color: Colors.black),
              ),
              SizedBox(width: padding),
              Text(
                "Vehicle Status",
                style: GoogleFonts.inter(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          SizedBox(height: padding + 4),

          // Pie Chart
          SizedBox(
            height: chartHeight,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = null;
                        return;
                      }
                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 0,
                centerSpaceRadius: centerRadius,
                sections: statusData.asMap().entries.map((entry) {
                  final i = entry.key;
                  final data = entry.value;
                  final isTouched = i == touchedIndex;

                  return PieChartSectionData(
                    color: colors[i],
                    value: data["percent"],
                    title: isTouched ? '${data["percent"]}%' : '',
                    radius: isTouched ? touchedRadius : baseRadius,
                    titleStyle: GoogleFonts.inter(
                      fontSize: isTouched ? touchedFontSize : normalFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          SizedBox(height: padding + 4),

          // Legend
          Wrap(
            spacing: padding,
            runSpacing: AdaptiveUtils.getLeftSectionSpacing(screenWidth),
            children: statusData.asMap().entries.map((entry) {
              final i = entry.key;
              final data = entry.value;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors[i],
                    ),
                  ),
                  SizedBox(width: padding / 2),
                  Text(
                    data["label"],
                    style: GoogleFonts.inter(
                      fontSize: legendFontSize,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    data["count"],
                    style: GoogleFonts.inter(
                      fontSize: legendFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${data["percent"]}%)',
                    style: GoogleFonts.inter(
                      fontSize: legendFontSize,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}