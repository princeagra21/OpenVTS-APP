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

  Color _lighten(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final int red = (color.red + (255 - color.red) * amount).round();
    final int green = (color.green + (255 - color.green) * amount).round();
    final int blue = (color.blue + (255 - color.blue) * amount).round();
    return Color.fromARGB(color.alpha, red, green, blue);
  }

  Color _darken(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final int red = (color.red * (1 - amount)).round();
    final int green = (color.green * (1 - amount)).round();
    final int blue = (color.blue * (1 - amount)).round();
    return Color.fromARGB(color.alpha, red, green, blue);
  }

  List<Color> getColors(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final modeBrightness = Theme.of(context).brightness;
    final primaryBrightness = ThemeData.estimateBrightnessForColor(primary);

    if (modeBrightness == primaryBrightness) {
      // Potential contrast issue: shift primary towards opposite brightness
      if (primaryBrightness == Brightness.dark) {
        // Dark primary on dark mode: lighten
        final shifted = _lighten(primary, 0.4);
        return [
          shifted,
          _darken(shifted, 0.2),
          _darken(shifted, 0.4),
          _darken(shifted, 0.6),
        ];
      } else {
        // Light primary on light mode: darken
        final shifted = _darken(primary, 0.4);
        return [
          shifted,
          _lighten(shifted, 0.2),
          _lighten(shifted, 0.4),
          _lighten(shifted, 0.6),
        ];
      }
    } else {
      // Good contrast: use primary with darkening for shades
      return [
        primary,
        _darken(primary, 0.3),
        _darken(primary, 0.5),
        _darken(primary, 0.7),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    // All sizes from our shared AdaptiveUtils
    final double padding         = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double titleFontSize   = AdaptiveUtils.getSubtitleFontSize(screenWidth);     // 14-18
    final double legendFontSize  = AdaptiveUtils.getTitleFontSize(screenWidth) + 1;    // 12-14
    final double chartHeight     = AdaptiveUtils.isVerySmallScreen(screenWidth)
        ? 180 : AdaptiveUtils.isSmallScreen(screenWidth) ? 200 : 220;

    // Touch feedback scaling
    final double baseRadius      = AdaptiveUtils.getButtonSize(screenWidth) + 34; // ~62-70
    final double touchedRadius   = baseRadius + 20;
    final double centerRadius    = AdaptiveUtils.getIconSize(screenWidth) + 14;     // ~30-34

    final double touchedFontSize = titleFontSize;
    final double normalFontSize  = AdaptiveUtils.getTitleFontSize(screenWidth);     // 11-13

    final colors = getColors(context);

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
          // Header: Icon + Title
          Row(
            children: [
              CircleAvatar(
                radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.2,
                backgroundColor: colorScheme.surfaceVariant,
                child: Icon(Icons.directions_car, color: colorScheme.primary),
              ),
              SizedBox(width: padding),
              Text(
                "Vehicle Status",
                style: GoogleFonts.inter(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
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

                  final sectionColor = colors[i];
                  final textColor = ThemeData.estimateBrightnessForColor(sectionColor) == Brightness.light 
                      ? Colors.black 
                      : Colors.white;

                  return PieChartSectionData(
                    color: sectionColor,
                    value: data["percent"],
                    title: isTouched ? '${data["percent"]}%' : '',
                    radius: isTouched ? touchedRadius : baseRadius,
                    titleStyle: GoogleFonts.inter(
                      fontSize: isTouched ? touchedFontSize : normalFontSize,
                      fontWeight: FontWeight.bold,
                      color: textColor,
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
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    data["count"],
                    style: GoogleFonts.inter(
                      fontSize: legendFontSize,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${data["percent"]}%)',
                    style: GoogleFonts.inter(
                      fontSize: legendFontSize,
                      color: colorScheme.onSurfaceVariant,
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