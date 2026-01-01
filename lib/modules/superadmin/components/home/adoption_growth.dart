// components/home/adoption_growth.dart
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../utils/app_utils.dart';

class AdoptionGrowthBox extends StatefulWidget {
  const AdoptionGrowthBox({super.key});

  @override
  State<AdoptionGrowthBox> createState() => _AdoptionGrowthBoxState();
}

class _AdoptionGrowthBoxState extends State<AdoptionGrowthBox> {
  int selectedIndex = 0;

  static const List<String> periods = ["12M", "6M", "3M"];
  static const List<String> descriptions = [
    "Last 12 months",
    "Last 6 months",
    "Last 3 months"
  ];

  // Fake beautiful growth data
  final List<List<FlSpot>> chartData = [
    // 12M
    [
      FlSpot(0, 1.2), FlSpot(1, 1.5), FlSpot(2, 1.8), FlSpot(3, 2.1),
      FlSpot(4, 2.4), FlSpot(5, 2.9), FlSpot(6, 3.3), FlSpot(7, 3.8),
      FlSpot(8, 4.4), FlSpot(9, 5.1), FlSpot(10, 5.9), FlSpot(11, 6.8),
    ],
    // 6M
    [FlSpot(0, 3.3), FlSpot(1, 3.8), FlSpot(2, 4.4), FlSpot(3, 5.1), FlSpot(4, 5.9), FlSpot(5, 6.8)],
    // 3M
    [FlSpot(0, 4.4), FlSpot(1, 5.1), FlSpot(2, 5.9), FlSpot(3, 6.8)],
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spots = chartData[selectedIndex];

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: isDark
                ? Colors.white.withOpacity(0.09)
                : Colors.white.withOpacity(0.72),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.7),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(isDark ? 0.2 : 0.4),
                blurRadius: 25,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Period Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Adoption & Growth",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.3,
                    ),
                  ),
                  _buildPeriodSelector(isDark),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                descriptions[selectedIndex],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),

              const SizedBox(height: 28),

              // GLORIOUS LINE CHART (Fixed tooltip params)
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchSpotThreshold: 40, // Smoother touch detection
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBorderRadius: BorderRadius.circular(16), // Fixed: Correct name
                        tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        tooltipMargin: 8,
                        getTooltipColor: (touchedSpot) => Colors.black.withOpacity(0.85), // Custom bg color
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              '${spot.y.toStringAsFixed(1)}k',
                              TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: Colors.cyanAccent,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Colors.cyanAccent.withOpacity(0.4),
                              Colors.cyanAccent.withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        shadow: Shadow(
                          color: Colors.cyanAccent.withOpacity(0.6),
                          blurRadius: 20,
                        ),
                      ),
                    ],
                    minX: 0,
                    maxX: spots.length - 1.toDouble(),
                    minY: 0,
                    maxY: spots.last.y + 1,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Final stat highlight
              Center(
                child: Text(
                  "+68% from last period",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.cyanAccent,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.cyanAccent.withOpacity(0.6),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(periods.length, (i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => setState(() => selectedIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutExpo,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: selected
                    ? (isDark ? Colors.white : Colors.black)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                periods[i],
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? (isDark ? Colors.black : Colors.white)
                      : (isDark ? Colors.white70 : Colors.grey[700]),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}