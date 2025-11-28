import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class SmallTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedBackground;

  const SmallTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedBackground,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 420;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 10 : 14,
          vertical: isSmallScreen ? 5 : 6,
        ),
        decoration: BoxDecoration(
          color: selected ? (selectedBackground ?? Colors.black) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isSmallScreen ? 10.58 : 11.96,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

class AdoptionGrowthBox extends StatefulWidget {
  const AdoptionGrowthBox({super.key});

  @override
  State<AdoptionGrowthBox> createState() => _AdoptionGrowthBoxState();
}

class _AdoptionGrowthBoxState extends State<AdoptionGrowthBox> {
  String monthTab = "12M";
  Set<String> selectedStats = {"Vehicles", "Users", "Licenses"};

  final List<double> vehicles = [12, 22, 18, 30, 34, 20, 15, 25, 28, 32, 38, 40];
  final List<double> users = [10, 15, 12, 21, 25, 19, 22, 27, 30, 35, 37, 39];
  final List<double> licenses = [5, 10, 15, 14, 16, 18, 20, 22, 24, 26, 29, 30];

  final Map<String, Color> statColors = {
  "Vehicles": Colors.black.withOpacity(1),     // Full black
  "Users": Colors.black.withOpacity(0.7),      // Dark grey
  "Licenses": Colors.black.withOpacity(0.5),   // Lighter grey
};


  List<double> getDataFor(String stat) {
    List<double> base = switch (stat) {
      "Vehicles" => vehicles,
      "Users" => users,
      _ => licenses,
    };

    return switch (monthTab) {
      "3M" => base.sublist(9),
      "6M" => base.sublist(6),
      _ => base,
    };
  }

  int get numMonths {
    return switch (monthTab) {
      "3M" => 3,
      "6M" => 6,
      _ => 12,
    };
  }

  double get yMax {
    if (selectedStats.isEmpty) return 10;
    final allValues = selectedStats.map((stat) => getDataFor(stat)).expand((d) => d).toList();
    final maxVal = allValues.reduce((a, b) => a > b ? a : b);
    return (maxVal / 10).ceil() * 10 + 5; // little headroom
  }

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

    final monthTabs = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: ["12M", "6M", "3M"].map((tab) {
          return SmallTab(
            label: tab,
            selected: monthTab == tab,
            onTap: () => setState(() => monthTab = tab),
          );
        }).toList(),
      ),
    );

    final header = isSmallScreen
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Adoption and growth",
                style: titleStyle,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: monthTabs,
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Adoption and growth",
                style: titleStyle,
              ),
              const Spacer(),
              monthTabs,
            ],
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
          header,
          const SizedBox(height: 12),
          // Subheader + Stat Tabs
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Last $monthTab months",
                style: GoogleFonts.inter(
                  fontSize: isSmallScreen ? 11.96 : 12.88,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              // Stat Tabs – Wrap on small screens
              Center(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: ["Vehicles", "Users", "Licenses"].map((tab) {
                    return SmallTab(
                      label: tab,
                      selected: selectedStats.contains(tab),
                      onTap: () => setState(() {
                        if (selectedStats.contains(tab)) {
                          selectedStats.remove(tab);
                        } else {
                          selectedStats.add(tab);
                        }
                      }),
                      selectedBackground: statColors[tab],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Chart – Responsive height & font sizes
          SizedBox(
            height: isVerySmallScreen ? 180 : isSmallScreen ? 200 : 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: yMax,
                lineTouchData: const LineTouchData(enabled: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: yMax / 3,
                      reservedSize: isSmallScreen ? 32 : 40,
                       getTitlesWidget: (value, meta) => SideTitleWidget(
  meta: meta, // pass the required argument
  child: Text(
    "${value.toInt()}K",
    style: GoogleFonts.inter(
      fontSize: isVerySmallScreen ? 7.2 : 8.8,
      color: Colors.black87,
    ),
  ),
),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= numMonths) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            "M${index + 1}",
                            style: GoogleFonts.inter(
                              fontSize: isVerySmallScreen ? 7.82 : 9.2,
                              color: Colors.black54,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: yMax / 3,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(color: Colors.black12, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: selectedStats.map((stat) {
                  final data = getDataFor(stat);
                  final color = statColors[stat]!;
                  return LineChartBarData(
                    spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    barWidth: isSmallScreen ? 2.875 : 3.45,
                    color: color,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                        radius: isSmallScreen ? 4.025 : 4.6,
                        color: color,
                        strokeColor: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}