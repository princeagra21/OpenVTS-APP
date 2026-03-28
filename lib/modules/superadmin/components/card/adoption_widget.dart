// components/charts/adoption_growth_box.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/superadmin_adoption_graph.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:flutter/foundation.dart';
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

    final double hPadding =
        AdaptiveUtils.getHorizontalPadding(screenWidth) - 4; // 4-12
    final double vPadding =
        AdaptiveUtils.getLeftSectionSpacing(screenWidth) - 2; // 4-8
    final double fontSize = AdaptiveUtils.getTitleFontSize(
      screenWidth,
    ); // 11-13

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
        decoration: BoxDecoration(
          color: selected
              ? (selectedBackground ?? colorScheme.primary)
              : Colors.transparent,
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
  final Set<String> selectedStats = {"Vehicles", "Users", "Licenses"};

  SuperadminAdoptionGraph? _graph;
  bool _loadingGraph = false;
  bool _graphErrorShown = false;
  CancelToken? _graphCancelToken;

  ApiClient? _api;
  SuperadminRepository? _repo;

  @override
  void initState() {
    super.initState();
    _loadGraph();
  }

  @override
  void dispose() {
    _graphCancelToken?.cancel('AdoptionGrowthBox disposed');
    super.dispose();
  }

  Future<void> _loadGraph() async {
    _graphCancelToken?.cancel('Reload adoption graph');
    final token = CancelToken();
    _graphCancelToken = token;

    if (!mounted) return;
    setState(() => _loadingGraph = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final res = await _repo!.getAdoptionGraph(cancelToken: token);
      if (!mounted) return;

      res.when(
        success: (graph) {
          if (kDebugMode) {
            debugPrint(
              '[Home] GET /superadmin/dashboard/adoptiongraph status=2xx '
              'vehicles=${graph.vehicles().length} users=${graph.users().length} '
              'licenses=${graph.licenses().length}',
            );
          }
          if (!mounted) return;
          setState(() {
            _graph = graph;
            _loadingGraph = false;
            _graphErrorShown = false;
          });
        },
        failure: (err) {
          if (kDebugMode) {
            final status = err is ApiException ? err.statusCode : null;
            debugPrint(
              '[Home] GET /superadmin/dashboard/adoptiongraph status=${status ?? 'error'}',
            );
          }
          if (!mounted) return;
          setState(() => _loadingGraph = false);
          if (_graphErrorShown) return;
          _graphErrorShown = true;

          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? "Not authorized to view growth data."
              : "Couldn't load growth data.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (kDebugMode) {
        debugPrint(
          '[Home] GET /superadmin/dashboard/adoptiongraph status=error',
        );
      }
      if (!mounted) return;
      setState(() => _loadingGraph = false);
      if (_graphErrorShown) return;
      _graphErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load growth data.")),
      );
    }
  }

  Map<String, Color> getStatColors(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return {
      "Vehicles": colorScheme.primary,
      "Users": colorScheme.primary.withOpacity(0.7),
      "Licenses": colorScheme.primary.withOpacity(0.5),
    };
  }

  Widget _legendItem(
    BuildContext context, {
    required String label,
    required Color color,
    required double fontSize,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  List<double> getDataFor(String stat) {
    final graph = _graph;
    final base = switch (stat) {
      "Vehicles" => graph?.vehicles() ?? List<double>.filled(12, 0),
      "Users" => graph?.users() ?? List<double>.filled(12, 0),
      _ => graph?.licenses() ?? List<double>.filled(12, 0),
    };

    return switch (monthTab) {
      "3M" => base.sublist(9),
      "6M" => base.sublist(6),
      "12M" => base,
      _ => base,
    };
  }

  int get numMonths => switch (monthTab) {
    "3M" => 3,
    "6M" => 6,
    "12M" => 12,
    _ => _graph?.vehicles().length ?? 12,
  };

  double get yMax {
    if (selectedStats.isEmpty) return 10;
    final allValues = selectedStats.expand((s) => getDataFor(s));
    final maxVal = allValues.reduce((a, b) => a > b ? a : b);
    if (maxVal <= 10) return 10;
    return (maxVal / 10).ceil() * 10;
  }

  String _formatYAxisValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
    }
    return value.toInt().toString();
  }

  List<String> _monthLabels(int count) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final now = DateTime.now();
    return List.generate(count, (i) {
      final idxFromEnd = count - 1 - i;
      final date = DateTime(now.year, now.month - idxFromEnd, 1);
      final month = months[date.month - 1];
      final year = (date.year % 100).toString().padLeft(2, '0');
      return "$month '$year";
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    // All sizes from AdaptiveUtils — pure and clean
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double titleFontSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double subheaderFontSize =
        AdaptiveUtils.getTitleFontSize(screenWidth) - 3;
    final double chartHeight = AdaptiveUtils.isVerySmallScreen(screenWidth)
        ? 180
        : AdaptiveUtils.isSmallScreen(screenWidth)
        ? 200
        : 220;

    final double leftTitleFontSize =
        AdaptiveUtils.getTitleFontSize(screenWidth) - 3; // ~8-10
    final double bottomTitleFontSize =
        AdaptiveUtils.getTitleFontSize(screenWidth) - 2; // ~9-11
    final double lineWidth =
        AdaptiveUtils.getIconSize(screenWidth) / 6; // ~2.7-3.3
    final double dotRadius = AdaptiveUtils.getIconSize(screenWidth) / 4; // ~4-5
    final double spacing = AdaptiveUtils.getIconPaddingLeft(screenWidth) - 4;

    final titleStyle = GoogleFonts.inter(
      fontSize: titleFontSize,
      fontWeight: FontWeight.bold,
      color: colorScheme.onSurface,
    );
    final showSkeleton = _loadingGraph;

    final statColors = getStatColors(context);
    const statsOrder = ['Vehicles', 'Users', 'Licenses'];
    final statsList = statsOrder.where(selectedStats.contains).toList();
    final labels = _monthLabels(numMonths);

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
          SizedBox(width: spacing),
          SmallTab(
            label: "All",
            selected: monthTab == "All",
            onTap: () => setState(() => monthTab = "All"),
          ),
        ],
      ),
    );

    final header = screenWidth < 420
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: "Adoption and growth", style: titleStyle),
                    if (_loadingGraph)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: AppShimmer(width: 14, height: 14, radius: 7),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: padding / 2),
              Align(alignment: Alignment.centerRight, child: monthTabs),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: "Adoption and growth", style: titleStyle),
                    if (_loadingGraph)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: AppShimmer(width: 14, height: 14, radius: 7),
                        ),
                      ),
                  ],
                ),
              ),
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
          if (showSkeleton) ...[
            AppShimmer(
              width: screenWidth * 0.34,
              height: subheaderFontSize + 8,
              radius: 8,
            ),
            SizedBox(height: padding),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppShimmer(width: screenWidth * 0.2, height: 32, radius: 12),
                SizedBox(width: spacing),
                AppShimmer(width: screenWidth * 0.2, height: 32, radius: 12),
                SizedBox(width: spacing),
                AppShimmer(width: screenWidth * 0.2, height: 32, radius: 12),
              ],
            ),
            SizedBox(height: padding + 4),
            SizedBox(
              height: chartHeight,
              child: AppShimmer(
                width: double.infinity,
                height: chartHeight,
                radius: 18,
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _legendItem(
                  context,
                  label: 'Vehicles',
                  color: statColors['Vehicles']!,
                  fontSize: subheaderFontSize + 2,
                ),
                SizedBox(width: spacing + 6),
                _legendItem(
                  context,
                  label: 'Users',
                  color: statColors['Users']!,
                  fontSize: subheaderFontSize + 2,
                ),
                SizedBox(width: spacing + 6),
                _legendItem(
                  context,
                  label: 'Licenses',
                  color: statColors['Licenses']!,
                  fontSize: subheaderFontSize + 2,
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
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBorderRadius: BorderRadius.circular(8),
                      tooltipPadding: const EdgeInsets.all(10),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipColor: (_) => colorScheme.surface,
                      getTooltipItems: (touchedSpots) {
                        if (touchedSpots.isEmpty) return [];
                        final index = touchedSpots.first.x.toInt();
                        final monthLabel =
                            index >= 0 && index < labels.length
                                ? labels[index]
                                : 'Month';

                        final children = <TextSpan>[];
                        for (final stat in statsList) {
                          final data = getDataFor(stat);
                          if (index >= data.length) continue;
                          final color = statColors[stat]!;
                          children.add(
                            TextSpan(
                              text:
                                  '\n$stat: ${_formatYAxisValue(data[index])}',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                                fontSize: subheaderFontSize + 2,
                              ),
                            ),
                          );
                        }

                        final item = LineTooltipItem(
                          monthLabel,
                          TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: subheaderFontSize + 2,
                          ),
                          children: children,
                        );
                        return List<LineTooltipItem>.generate(
                          touchedSpots.length,
                          (_) => item,
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: yMax / 3,
                        reservedSize: screenWidth < 420 ? 32 : 40,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta, // pass the required argument
                          child: Text(
                            _formatYAxisValue(value),
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
                        interval: 2,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index % 2 != 0) return const SizedBox();
                          if (index >= labels.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[index],
                              style: GoogleFonts.inter(
                                fontSize: bottomTitleFontSize,
                                color: colorScheme.onSurface.withOpacity(0.54),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: yMax / 3,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: colorScheme.onSurface.withOpacity(0.12),
                      strokeWidth: 1,
                      dashArray: [6, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: statsList.asMap().entries.map((e) {
                    final stat = e.value;
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
                      dotData: const FlDotData(show: false),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
