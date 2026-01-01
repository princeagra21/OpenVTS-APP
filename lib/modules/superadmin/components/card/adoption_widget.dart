// components/charts/adoption_growth_box.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/adaptive_utils.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double hPadding = AdaptiveUtils.getHorizontalPadding(screenWidth) - 4; // 4-12
    final double vPadding = AdaptiveUtils.getLeftSectionSpacing(screenWidth) - 2; // 4-8
    final double fontSize = AdaptiveUtils.getTitleFontSize(screenWidth); // 11-13

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: hPadding,
          vertical: vPadding,
        ),
        decoration: BoxDecoration(
          color: selected ? (selectedBackground ?? colorScheme.primary) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.onSurface, width: 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
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

  Map<String, Color> getStatColors(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return {
      "Vehicles": colorScheme.primary,
      "Users": colorScheme.primary.withOpacity(0.7),
      "Licenses": colorScheme.primary.withOpacity(0.5),
    };
  }

  List<double> getDataFor(String stat) {
    final base = switch (stat) {
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

  int get numMonths => switch (monthTab) { "3M" => 3, "6M" => 6, _ => 12 };

  double get yMax {
    if (selectedStats.isEmpty) return 10;
    final allValues = selectedStats.expand((s) => getDataFor(s));
    final maxVal = allValues.reduce((a, b) => a > b ? a : b);
    return (maxVal / 10).ceil() * 10 + 5;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    // All sizes from AdaptiveUtils — pure and clean
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2 ;
    final double subheaderFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) - 3;
    final double chartHeight = AdaptiveUtils.isVerySmallScreen(screenWidth)
    ? 180
    : AdaptiveUtils.isSmallScreen(screenWidth)
        ? 200
        : 220;

    final double leftTitleFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) - 3; // ~8-10
    final double bottomTitleFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) - 2; // ~9-11
    final double lineWidth = AdaptiveUtils.getIconSize(screenWidth) / 6; // ~2.7-3.3
    final double dotRadius = AdaptiveUtils.getIconSize(screenWidth) / 4; // ~4-5
    final double spacing = AdaptiveUtils.getIconPaddingLeft(screenWidth) - 4;

    final titleStyle = GoogleFonts.inter(
      fontSize: titleFontSize,
      fontWeight: FontWeight.bold,
      color: colorScheme.onSurface,
    );

    final statColors = getStatColors(context);

    final monthTabs = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
       // border: Border.all(color: Colors.black),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SmallTab(
            label: "12M",
            selected: monthTab == "12M",
            onTap: () => setState(() => monthTab = "12M"),
          ),
          SizedBox(width: spacing),
          SmallTab(
            label: "6M",
            selected: monthTab == "6M",
            onTap: () => setState(() => monthTab = "6M"),
          ),
          SizedBox(width: spacing),
          SmallTab(
            label: "3M",
            selected: monthTab == "3M",
            onTap: () => setState(() => monthTab = "3M"),
          ),
        ],
      ),
    );

    final header = screenWidth < 420
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Adoption and growth", style: titleStyle),
              SizedBox(height: padding / 2),
              Align(alignment: Alignment.centerRight, child: monthTabs),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Adoption and growth", style: titleStyle),
              monthTabs,
            ],
          );

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
          header,
          SizedBox(height: padding),
          Text(
            "Last $monthTab months",
            style: GoogleFonts.inter(
              fontSize: subheaderFontSize,
              color: colorScheme.onSurface.withOpacity(0.87),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: padding),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SmallTab(
                label: "Vehicles",
                selected: selectedStats.contains("Vehicles"),
                selectedBackground: statColors["Vehicles"],
                onTap: () => setState(() {
                  selectedStats.contains("Vehicles")
                      ? selectedStats.remove("Vehicles")
                      : selectedStats.add("Vehicles");
                }),
              ),
              SizedBox(width: spacing),
              SmallTab(
                label: "Users",
                selected: selectedStats.contains("Users"),
                selectedBackground: statColors["Users"],
                onTap: () => setState(() {
                  selectedStats.contains("Users")
                      ? selectedStats.remove("Users")
                      : selectedStats.add("Users");
                }),
              ),
              SizedBox(width: spacing),
              SmallTab(
                label: "Licenses",
                selected: selectedStats.contains("Licenses"),
                selectedBackground: statColors["Licenses"],
                onTap: () => setState(() {
                  selectedStats.contains("Licenses")
                      ? selectedStats.remove("Licenses")
                      : selectedStats.add("Licenses");
                }),
              ),
            ],
          ),
          SizedBox(height: padding + 4),
          SizedBox(
            height: chartHeight,
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
                      reservedSize: screenWidth < 420 ? 32 : 40,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
  meta: meta, // pass the required argument
  child: Text(
    "${value.toInt()}K",
    style: GoogleFonts.inter(
      fontSize: leftTitleFontSize,
      color: colorScheme.onSurface.withOpacity(0.87),
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
                              fontSize: bottomTitleFontSize,
                              color: colorScheme.onSurface.withOpacity(0.54),
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
                  getDrawingHorizontalLine: (_) => FlLine(color: colorScheme.onSurface.withOpacity(0.12), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: selectedStats.map((stat) {
                  final data = getDataFor(stat);
                  final color = statColors[stat]!;
                  return LineChartBarData(
                    spots: data
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    barWidth: lineWidth,
                    color: color,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                        radius: dotRadius,
                        color: color,
                        strokeColor: colorScheme.surface,
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