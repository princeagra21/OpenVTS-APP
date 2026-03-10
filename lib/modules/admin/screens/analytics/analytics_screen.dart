// screens/analytics/analytics_screen.dart
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final DateTime currentDate = DateTime(2025, 12, 26);

  // Hardcoded stats as per provided data
  int tracked = 0;
  int expiring = 0;
  int overdue = 0;
  int suspended = 0;
  double mrr = 0.0;
  double arpu = 0.0;
  double valueAtRisk = 0.0;
  int renewalRate = 0;
  int churn = 0;

  final List<Map<String, dynamic>> topCustomers =
      const <Map<String, dynamic>>[];

  double collectionSuccess = 0.0;
  int atRisk = 0;
  double avgTicket = 0.0;
  int largeCustomers = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final double titleFs = AdaptiveUtils.getTitleFontSize(width);
    final double bodyFs = titleFs - 1;
    final double smallFs = titleFs - 3;
    final double cardPadding = hp + 4;

    final f = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    final trackedText = tracked > 0 ? tracked.toString() : '—';
    final expiringText = expiring > 0 ? expiring.toString() : '—';
    final overdueText = overdue > 0 ? overdue.toString() : '—';
    final suspendedText = suspended > 0 ? suspended.toString() : '—';
    final mrrText = mrr > 0 ? f.format(mrr) : '—';
    final arpuText = arpu > 0 ? f.format(arpu) : '—';
    final valueAtRiskText = valueAtRisk > 0 ? f.format(valueAtRisk) : '—';
    final renewalRateText = renewalRate > 0 ? '$renewalRate%' : '—';
    final churnText = churn > 0 ? '$churn%' : '—';
    final collectionSuccessText = collectionSuccess > 0
        ? "${collectionSuccess.toInt()}%"
        : '—';
    final atRiskText = atRisk > 0 ? atRisk.toString() : '—';
    final avgTicketText = avgTicket > 0 ? f.format(avgTicket) : '—';
    final largeCustomersText = largeCustomers > 0
        ? largeCustomers.toString()
        : '—';

    return AppLayout(
      title: "ADMIN",
      subtitle: "Analytics",
      actionIcons: const [],
      showLeftAvatar: false,
      leftAvatarText: 'SA',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FILTER TABS
            Row(
              children: [
                SmallTab(label: "Last 30 days", selected: true, onTap: () {}),
                SizedBox(width: spacing),
                SmallTab(label: "All plans", selected: true, onTap: () {}),
              ],
            ),
            SizedBox(height: hp),

            // STATS
            Container(
              padding: EdgeInsets.symmetric(vertical: hp),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statBox(
                        "Tracked devices",
                        trackedText,
                        "",
                        bodyFs,
                        smallFs,
                        colorScheme,
                        spacing,
                      ),
                      _statBox(
                        "Expiring (<30d)",
                        expiringText,
                        "Act now",
                        bodyFs,
                        smallFs,
                        colorScheme,
                        spacing,
                      ),
                      _statBox(
                        "Overdue",
                        overdueText,
                        "Suspension risk",
                        bodyFs,
                        smallFs,
                        colorScheme,
                        spacing,
                      ),
                      _statBox(
                        "Suspended",
                        suspendedText,
                        "Disabled access",
                        bodyFs,
                        smallFs,
                        colorScheme,
                        spacing,
                      ),
                    ],
                  ),
                  SizedBox(height: hp / 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statBox(
                        "MRR (est.)",
                        mrrText,
                        "From current plans",
                        bodyFs,
                        smallFs,
                        colorScheme,
                        spacing,
                      ),
                      _statBox(
                        "ARPU",
                        arpuText,
                        "MRR / device",
                        bodyFs,
                        smallFs,
                        colorScheme,
                        spacing,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: hp),

            // CASHFLOW CHART
            CashflowBox(),
            SizedBox(height: hp),

            // RENEWALS WINDOW
            Container(
              padding: EdgeInsets.all(cardPadding),
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
                  // TITLE
                  Text(
                    "Renewal Overview",
                    style: GoogleFonts.inter(
                      fontSize: bodyFs + 2,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  SizedBox(height: spacing / 3),

                  // SUBTITLE
                  Text(
                    "Upcoming renewals within 30 days",
                    style: GoogleFonts.inter(
                      fontSize: smallFs,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),

                  SizedBox(height: spacing),

                  // AMOUNT
                  Text(
                    valueAtRiskText,
                    style: GoogleFonts.inter(
                      fontSize: titleFs + 6,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),

                  SizedBox(height: spacing / 3),

                  // DEVICES TEXT
                  Text(
                    expiring > 0 ? "$expiring devices expiring soon" : "—",
                    style: GoogleFonts.inter(
                      fontSize: smallFs,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),

                  SizedBox(height: spacing),

                  // STATS BOXES
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.trending_up, color: Colors.green),
                              SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Renewal rate (est.)",
                                    style: GoogleFonts.inter(
                                      fontSize: smallFs,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    renewalRateText,
                                    style: GoogleFonts.inter(
                                      fontSize: bodyFs,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(width: spacing),

                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.trending_down, color: Colors.red),
                              SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Churn (est.)",
                                    style: GoogleFonts.inter(
                                      fontSize: smallFs,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    churnText,
                                    style: GoogleFonts.inter(
                                      fontSize: bodyFs,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: spacing + 3),

                  // SEND REMINDER BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: Icon(
                        Icons.notifications_active_outlined,
                        color: colorScheme.primary,
                      ),
                      label: Text("Send Reminder"),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: hp),

            // TOP CUSTOMERS
            Text(
              "Top Customers • Expiring Value",
              style: GoogleFonts.inter(
                fontSize: bodyFs + 2,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              "Next 30 days",
              style: GoogleFonts.inter(
                fontSize: smallFs,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            SizedBox(height: spacing),
            if (topCustomers.isEmpty)
              Container(
                margin: EdgeInsets.only(bottom: hp),
                padding: EdgeInsets.all(cardPadding),
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
                child: Text(
                  "—",
                  style: GoogleFonts.inter(
                    fontSize: bodyFs,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              )
            else
              ...topCustomers.asMap().entries.map((entry) {
                final index = entry.key;
                final cust = entry.value;

                return Container(
                  margin: EdgeInsets.only(bottom: hp),
                  padding: EdgeInsets.all(cardPadding),
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
                      // NAME + BUTTON ROW
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "#${index + 1} ${cust['name']}",
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: bodyFs,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {},
                            icon: Icon(
                              Icons.notifications_active_outlined,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            label: Text(
                              "Remind",
                              style: GoogleFonts.inter(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 6),

                      // POTENTIAL UNDER NAME
                      Text(
                        "Potential: ${f.format(cust['potential'])}",
                        style: GoogleFonts.inter(
                          fontSize: bodyFs - 1,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

            SizedBox(height: hp),

            // OPERATIONS PULSE
            Container(
              padding: EdgeInsets.all(cardPadding),
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
                  Text(
                    "Operations Pulse",
                    style: GoogleFonts.inter(
                      fontSize: bodyFs + 2,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    "Quick health across the funnel",
                    style: GoogleFonts.inter(
                      fontSize: smallFs,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),

                  SizedBox(height: spacing),

                  // COLLECTION SUCCESS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: colorScheme.primary.withOpacity(0.5),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Collection success (est.)",
                            style: GoogleFonts.inter(
                              fontSize: smallFs,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        collectionSuccessText,
                        style: GoogleFonts.inter(
                          fontSize: bodyFs,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: hp / 2),

                  // AT-RISK DEVICES
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: colorScheme.primary.withOpacity(0.5),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "At-risk devices",
                            style: GoogleFonts.inter(
                              fontSize: smallFs,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        atRiskText,
                        style: GoogleFonts.inter(
                          fontSize: bodyFs,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: hp / 2),

                  // AVG TICKET
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.payments_outlined,
                            color: colorScheme.primary.withOpacity(0.5),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Avg. ticket",
                            style: GoogleFonts.inter(
                              fontSize: smallFs,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        avgTicketText,
                        style: GoogleFonts.inter(
                          fontSize: bodyFs,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: hp / 2),

                  // LARGE CUSTOMERS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.devices_other_outlined,
                            color: colorScheme.primary.withOpacity(0.5),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Customers with >10 devices",
                            style: GoogleFonts.inter(
                              fontSize: smallFs,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        largeCustomersText,
                        style: GoogleFonts.inter(
                          fontSize: bodyFs,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: hp * 3),
          ],
        ),
      ),
    );
  }

  Widget _statBox(
    String title,
    String value,
    String subtitle,
    double bodyFs,
    double smallFs,
    ColorScheme colorScheme,
    double spacing,
  ) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: spacing / 2),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: smallFs,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: bodyFs,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary.withOpacity(0.5),
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: smallFs - 1,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CashflowBox extends StatefulWidget {
  const CashflowBox({super.key});

  @override
  State<CashflowBox> createState() => _CashflowBoxState();
}

class _CashflowBoxState extends State<CashflowBox> {
  Set<String> selectedStats = {"Online", "Manual"};
  int touchedIndex = -1;

  final List<double> online = [
    10476,
    1824,
    409,
    12149,
    4506,
    4012,
    3657,
    2286,
    12066,
    1679,
    11087,
    12135,
    14617,
    8935,
    1424,
    9674,
    6912,
    520,
    488,
    1535,
    3582,
    3811,
    8279,
    9863,
    434,
    9195,
    3257,
    11731,
    10647,
    11490,
  ];
  final List<double> manual = [
    4464,
    3436,
    1805,
    3679,
    4827,
    2278,
    53,
    1307,
    3462,
    2787,
    2276,
    1273,
    1763,
    2757,
    837,
    759,
    3112,
    792,
    2940,
    2817,
    4945,
    2166,
    355,
    3763,
    4392,
    1022,
    3100,
    645,
    4522,
    2401,
  ];

  final DateTime currentDate = DateTime(2025, 12, 26);

  List<double> getDataFor(String stat) {
    return stat == "Online" ? online : manual;
  }

  Map<String, Color> getStatColors(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return {"Online": colorScheme.secondary, "Manual": colorScheme.primary};
  }

  int get numDays => 30;

  double get yMax {
    final allValues = [...online, ...manual];
    if (allValues.isEmpty) return 10000;
    final maxVal = allValues.reduce((a, b) => a > b ? a : b);
    return (maxVal / 5000).ceil() * 5000 + 1000;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

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
        AdaptiveUtils.getTitleFontSize(screenWidth) - 3;
    final double bottomTitleFontSize =
        AdaptiveUtils.getTitleFontSize(screenWidth) - 2;
    final double lineWidth = AdaptiveUtils.getIconSize(screenWidth) / 6;
    final double dotRadius = AdaptiveUtils.getIconSize(screenWidth) / 4;
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth) - 4;

    final titleStyle = GoogleFonts.inter(
      fontSize: titleFontSize,
      fontWeight: FontWeight.bold,
      color: colorScheme.onSurface,
    );

    final statColors = getStatColors(context);
    final f = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final List<String> allStats = ["Online", "Manual"];

    final header = Text("Cashflow by Day", style: titleStyle);

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
          SizedBox(height: padding / 2),
          Text(
            "Online vs Manual collections",
            style: GoogleFonts.inter(
              fontSize: subheaderFontSize,
              color: colorScheme.onSurface.withOpacity(0.87),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: padding),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: allStats.map((stat) {
              final color = statColors[stat]!;
              final isSelected = selectedStats.contains(stat);
              final textOpacity = isSelected ? 1.0 : 0.5;
              return GestureDetector(
                onTap: () => setState(() {
                  if (isSelected) {
                    selectedStats.remove(stat);
                  } else {
                    selectedStats.add(stat);
                  }
                }),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                  child: Row(
                    children: [
                      Container(
                        width: dotRadius + 5,
                        height: dotRadius + 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        stat.toLowerCase(),
                        style: GoogleFonts.inter(
                          fontSize: subheaderFontSize + 5,
                          color: colorScheme.onSurface.withOpacity(textOpacity),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
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
                  touchCallback:
                      (FlTouchEvent event, LineTouchResponse? response) {
                        setState(() {
                          touchedIndex =
                              response?.lineBarSpots?.isNotEmpty == true
                              ? response!.lineBarSpots![0].spotIndex
                              : -1;
                        });
                      },
                  getTouchedSpotIndicator:
                      (LineChartBarData barData, List<int> spotIndices) {
                        return spotIndices.map((index) {
                          return TouchedSpotIndicatorData(
                            const FlLine(color: Colors.transparent),
                            FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, bar, i) =>
                                  FlDotCirclePainter(
                                    radius: dotRadius + 2,
                                    color: barData.color!,
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  ),
                            ),
                          );
                        }).toList();
                      },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots
                          .where((spot) {
                            final stat = allStats[spot.barIndex];
                            return selectedStats.contains(stat);
                          })
                          .map((spot) {
                            return LineTooltipItem(
                              f.format(spot.y.toInt()),
                              GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          })
                          .toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: yMax / 4,
                      reservedSize: screenWidth < 420 ? 32 : 40,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            NumberFormat.compactCurrency(
                              locale: 'en_IN',
                              symbol: '₹',
                            ).format(value.toInt()),
                            style: GoogleFonts.inter(
                              fontSize: leftTitleFontSize,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index % 5 != 0 || index >= numDays)
                          return const SizedBox();
                        final day = currentDate.subtract(
                          Duration(days: numDays - 1 - index),
                        );
                        final label = DateFormat('d MMM').format(day);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
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
                  horizontalInterval: yMax / 4,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: colorScheme.onSurface.withOpacity(0.12),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: allStats.map((stat) {
                  final data = getDataFor(stat);
                  final baseColor = statColors[stat]!;
                  final isSelected = selectedStats.contains(stat);
                  final opacity = isSelected
                      ? (stat == "Manual" ? 0.5 : 1.0)
                      : 0.3;
                  final color = baseColor.withOpacity(opacity);
                  return LineChartBarData(
                    spots: data
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    barWidth: lineWidth,
                    color: color,
                    belowBarData: BarAreaData(
                      show: true,
                      color: baseColor.withOpacity(0.1 * opacity),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
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
