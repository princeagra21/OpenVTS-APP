// screens/payments/payment_screen.dart
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedTab = "All";
  final TextEditingController _searchController = TextEditingController();

  DateTime _safeParseDateTime(String dateStr) {
    try {
      return DateFormat('dd MMM yyyy, HH:mm').parse(dateStr);
    } catch (e) {
      return DateTime.now();
    }
  }

  final List<Map<String, dynamic>> payments = const <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final double titleFs = AdaptiveUtils.getTitleFontSize(width);
    final double bodyFs = titleFs - 1;
    final double smallFs = titleFs - 3;
    final double iconSize = titleFs + 2;
    final double cardPadding = hp + 4;

    final f = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    final now = DateTime(2025, 12, 24);

    double todaySettled = 0;
    double monthSettled = 0;
    double online = 0;
    double manual = 0;
    final hasPayments = payments.isNotEmpty;

    for (var p in payments) {
      final d = _safeParseDateTime(p['date']);
      final amt = double.parse(
        p['total'].replaceAll('₹', '').replaceAll(',', ''),
      );
      if (p['status'] == "Settled") {
        if (d.year == now.year && d.month == now.month) {
          monthSettled += amt;
          if (d.day == now.day) {
            todaySettled += amt;
          }
        }
      }
      if (p['method_type'] == "Online") {
        online += amt;
      } else {
        manual += amt;
      }
    }

    final searchQuery = _searchController.text.toLowerCase();

    var filteredPayments =
        payments.where((p) {
          final matchesSearch =
              searchQuery.isEmpty ||
              p['customer'].toString().toLowerCase().contains(searchQuery) ||
              p['vehicle'].toString().toLowerCase().contains(searchQuery) ||
              p['imei'].toString().toLowerCase().contains(searchQuery) ||
              p['plan'].toString().toLowerCase().contains(searchQuery) ||
              p['method'].toString().toLowerCase().contains(searchQuery) ||
              p['status'].toString().toLowerCase().contains(searchQuery) ||
              p['ref'].toString().toLowerCase().contains(searchQuery) ||
              p['invoice'].toString().toLowerCase().contains(searchQuery);

          final matchesTab = selectedTab == "All" || p['status'] == selectedTab;

          return matchesSearch && matchesTab;
        }).toList()..sort(
          (a, b) => _safeParseDateTime(
            b['date'],
          ).compareTo(_safeParseDateTime(a['date'])),
        );

    return AppLayout(
      title: "ADMIN",
      subtitle: "Payments",
      actionIcons: const [CupertinoIcons.add],
      showLeftAvatar: false,
      leftAvatarText: 'SA',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SEARCH BAR
            Container(
              height: hp * 3.5,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(
                  fontSize: bodyFs,
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: "Search customer, vehicle, IMEI, plan...",
                  hintStyle: GoogleFonts.inter(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: bodyFs,
                  ),
                  prefixIcon: Icon(
                    CupertinoIcons.search,
                    size: iconSize,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  border: InputBorder.none,
                  focusColor: colorScheme.primary,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.transparent, width: 0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: hp,
                    vertical: hp,
                  ),
                ),
              ),
            ),
            SizedBox(height: hp),

            // STATS
            Container(
              padding: EdgeInsets.all(hp),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      _statBox(
                        "Collected Today",
                        hasPayments ? f.format(todaySettled) : "—",
                        "Settled only",
                        bodyFs,
                        smallFs,
                        colorScheme,
                        spacing,
                      ),
                      _statBox(
                        "This Month",
                        hasPayments ? f.format(monthSettled) : "—",
                        "Settled only",
                        bodyFs,
                        smallFs,
                        colorScheme,
                        spacing,
                      ),
                    ],
                  ),
                  SizedBox(height: hp / 2),
                  Row(
                    children: [
                      _statBox(
                        "Online",
                        hasPayments ? f.format(online) : "—",
                        "Razorpay/Stripe/etc",
                        bodyFs,
                        smallFs,
                        colorScheme,
                        spacing,
                      ),
                      _statBox(
                        "Manual",
                        hasPayments ? f.format(manual) : "—",
                        "UPI/Cash/Bank/Cheque",
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
            SizedBox(height: hp * 1.5),

            // TABS
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: ["All", "Settled", "Pending", "Refunded"].map((tab) {
                return SmallTab(
                  label: tab,
                  selected: selectedTab == tab,
                  onTap: () => setState(() => selectedTab = tab),
                );
              }).toList(),
            ),
            SizedBox(height: hp),

            // FILTERS
            Row(
              children: [
                Text(
                  "All statuses",
                  style: GoogleFonts.inter(
                    fontSize: smallFs,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                SizedBox(width: spacing),
                Text(
                  "All methods",
                  style: GoogleFonts.inter(
                    fontSize: smallFs,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                SizedBox(width: spacing),
                Text(
                  "Last 30 days",
                  style: GoogleFonts.inter(
                    fontSize: smallFs,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            SizedBox(height: hp),

            // COUNT + ADD BUTTON
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Showing ${filteredPayments.length} of ${payments.length} payments",
                  style: GoogleFonts.inter(
                    fontSize: bodyFs,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push("/admin/payments/add"),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: hp * 1.5,
                      vertical: spacing,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.primary),
                    ),
                    child: Text(
                      "Add Payment",
                      style: GoogleFonts.inter(
                        fontSize: bodyFs - 3,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 1.5),

            // PAYMENT CARDS
            if (filteredPayments.isEmpty)
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
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.money_dollar_circle,
                      size: AdaptiveUtils.getFsAvatarFontSize(width),
                      color: colorScheme.primary.withOpacity(0.7),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: Text(
                        "No payments found",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: bodyFs,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...filteredPayments.asMap().entries.map((entry) {
                final index = entry.key;
                final payment = entry.value;

                Color getStatusColor(String status) {
                  if (status == "Settled") return Colors.green;
                  if (status == "Pending") return Colors.orange;
                  if (status == "Refunded") return Colors.red;
                  return Colors.grey;
                }

                return AnimatedContainer(
                  duration: Duration(milliseconds: 300 + index * 50),
                  curve: Curves.easeOut,
                  margin: EdgeInsets.only(bottom: hp),
                  child: Container(
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
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(25),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: () {},
                        child: Padding(
                          padding: EdgeInsets.all(cardPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // TOP ROW
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: AdaptiveUtils.getAvatarSize(width),
                                    height: AdaptiveUtils.getAvatarSize(width),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colorScheme.primary.withOpacity(
                                          0.6,
                                        ),
                                      ),
                                    ),
                                    child: Icon(
                                      CupertinoIcons.money_dollar_circle,
                                      size: AdaptiveUtils.getFsAvatarFontSize(
                                        width,
                                      ),
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  SizedBox(width: spacing * 1.5),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              payment["date"],
                                              style: GoogleFonts.inter(
                                                fontSize: smallFs,
                                                color: colorScheme.onSurface
                                                    .withOpacity(0.6),
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: spacing + 4,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: getStatusColor(
                                                  payment["status"],
                                                ).withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Text(
                                                payment["status"],
                                                style: GoogleFonts.inter(
                                                  fontSize: smallFs,
                                                  fontWeight: FontWeight.w600,
                                                  color: getStatusColor(
                                                    payment["status"],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: spacing / 2),
                                        Text(
                                          payment["plan"],
                                          style: GoogleFonts.inter(
                                            fontSize: bodyFs + 2,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        SizedBox(height: spacing / 2),
                                        Text(
                                          payment["customer"],
                                          style: GoogleFonts.inter(
                                            fontSize: bodyFs,
                                            fontWeight: FontWeight.w500,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        SizedBox(height: spacing / 2),
                                        Text(
                                          "${payment["vehicle"]} • IMEI ${payment["imei"]}",
                                          style: GoogleFonts.inter(
                                            fontSize: bodyFs,
                                            fontWeight: FontWeight.w500,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        SizedBox(height: spacing / 2),
                                        Text(
                                          "${payment["method_type"]} ${payment["method"]}",
                                          style: GoogleFonts.inter(
                                            fontSize: bodyFs,
                                            fontWeight: FontWeight.w500,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        SizedBox(height: spacing / 2),
                                        Row(
                                          children: [
                                            Text(
                                              "Amount: ${payment["amount"]}",
                                              style: GoogleFonts.inter(
                                                fontSize: bodyFs - 1,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            SizedBox(width: spacing),
                                            Text(
                                              "Tax: ${payment["tax"]}",
                                              style: GoogleFonts.inter(
                                                fontSize: bodyFs - 1,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            SizedBox(width: spacing),
                                            Text(
                                              "Total: ${payment["total"]}",
                                              style: GoogleFonts.inter(
                                                fontSize: bodyFs - 1,
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: spacing),
                              Divider(
                                color: colorScheme.outline.withOpacity(0.3),
                              ),
                              SizedBox(height: spacing),
                              Text(
                                "Ref / Invoice: ${payment["ref"]} / ${payment["invoice"]}",
                                style: GoogleFonts.inter(
                                  fontSize: smallFs,
                                  color: colorScheme.onSurface.withOpacity(
                                    0.54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),

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
