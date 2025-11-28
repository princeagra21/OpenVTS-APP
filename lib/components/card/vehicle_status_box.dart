import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class VehicleStatusBox extends StatefulWidget {
  const VehicleStatusBox({super.key});

  @override
  State<VehicleStatusBox> createState() => _VehicleStatusBoxState();
}

class _VehicleStatusBoxState extends State<VehicleStatusBox> {
  int? touchedIndex;

  final List<Map<String, dynamic>> statusData = [
    {"label": "Running", "count": "2,986", "percent": 26.6},
    {"label": "Stop", "count": "111", "percent": 0.99},
    {"label": "Not Working (48 hours)", "count": "7,194", "percent": 64.08},
    {"label": "No Data", "count": "935", "percent": 8.33},
  ];

  final List<Color> colors = [
    Colors.black.withOpacity(1.0),
    Colors.black.withOpacity(0.7),
    Colors.black.withOpacity(0.4),
    Colors.black.withOpacity(0.1),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 420;
    final bool isVerySmallScreen = screenWidth < 360;

    final titleStyle = GoogleFonts.inter(
      fontSize: isVerySmallScreen ? 14.72 : 16.56,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

    final legendStyle = GoogleFonts.inter(
      fontSize: isSmallScreen ? 12 : 14,
      color: Colors.black,
    );

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[200],
                child: const Icon(Icons.directions_car, color: Colors.black),
              ),
              const SizedBox(width: 12),
              Text(
                "Vehicle Status",
                style: titleStyle,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: isVerySmallScreen ? 180 : isSmallScreen ? 200 : 220,
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
                centerSpaceRadius: isSmallScreen ? 30 : 40,
                sections: statusData.asMap().entries.map((entry) {
                  final i = entry.key;
                  final data = entry.value;
                  final isTouched = i == touchedIndex;
                  final fontSize = isTouched ? (isSmallScreen ? 14.0 : 16.0) : (isSmallScreen ? 10.0 : 12.0);
                  final radius = isTouched ? (isSmallScreen ? 80.0 : 100.0) : (isSmallScreen ? 70.0 : 90.0);

                  return PieChartSectionData(
                    color: colors[i],
                    value: data["percent"],
                    title: isTouched ? '${data["percent"]}%' : '',
                    radius: radius,
                    titleStyle: GoogleFonts.inter(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    showTitle: isTouched,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 8,
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
                  const SizedBox(width: 8),
                  Text(
                    data["label"],
                    style: legendStyle,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    data["count"],
                    style: legendStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${data["percent"]}%)',
                    style: legendStyle.copyWith(color: Colors.grey),
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