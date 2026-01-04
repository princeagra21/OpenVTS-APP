// screens/transactions/transaction_screen.dart
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/user/layout/app_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  String selectedTab = "All";
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _tabScrollController = ScrollController();
  late final List<String> _tabs;
  late final List<GlobalKey> _tabKeys;

  DateTime _safeParseDateTime(String dateStr) {
    try {
      // Parse only the date part to ignore time for consistent day-level calculations
      return DateFormat('dd/MM/yyyy').parse(dateStr.split(', ')[0]);
    } catch (e) {
      return DateTime(2025, 12, 25); // Consistent with the fixed 'now' date
    }
  }

  final List<Map<String, dynamic>> transactions = [
    {
      "id": 0,
      "date": "25/12/2025, 07:31:28",
      "invoice": "Invoice INV-2025-0101",
      "fs_id": "FS-47228846",
      "description": "Top-up: 10 credit-years",
      "method": "UPI",
      "credits": "+10",
      "amount": "₹14,990.00",
      "status": "Success",
    },
    {
      "id": 1,
      "date": "23/12/2025, 07:31:28",
      "invoice": "Invoice INV-2025-0097",
      "fs_id": "FS-E1NN8846",
      "description": "Stripe Card • **** 4242",
      "method": "Card",
      "credits": "+5",
      "amount": "₹7,495.00",
      "status": "Success",
    },
    {
      "id": 2,
      "date": "20/12/2025, 07:31:28",
      "invoice": "nb_7788",
      "fs_id": "FS-2QU78846",
      "description": "Awaiting bank confirmation",
      "method": "NetBanking",
      "credits": "+2",
      "amount": "₹2,998.00",
      "status": "Pending",
    },
    {
      "id": 3,
      "date": "18/12/2025, 07:31:28",
      "invoice": "upi_fail_8899",
      "fs_id": "FS-8BH28846",
      "description": "Insufficient funds",
      "method": "UPI",
      "credits": "+3",
      "amount": "₹4,497.00",
      "status": "Failed",
    },
    {
      "id": 4,
      "date": "13/12/2025, 07:31:28",
      "invoice": "re_93HG",
      "fs_id": "FS-PKYR8846",
      "description": "Refund for duplicate",
      "method": "Card",
      "credits": "-1",
      "amount": "-₹1,499.00",
      "status": "Refunded",
    },
    {
      "id": 5,
      "date": "11/12/2025, 07:31:28",
      "invoice": "rzp_w_9812",
      "fs_id": "FS-FHZC8846",
      "description": "Wallet promo",
      "method": "Wallet",
      "credits": "+1",
      "amount": "₹1,499.00",
      "status": "Success",
    },
    {
      "id": 6,
      "date": "30/11/2025, 07:31:28",
      "invoice": "upi_9922",
      "fs_id": "FS-U3PF8846",
      "description": "Bulk purchase 20",
      "method": "UPI",
      "credits": "+20",
      "amount": "₹29,980.00",
      "status": "Success",
    },
    {
      "id": 7,
      "date": "23/11/2025, 07:31:28",
      "invoice": "pi_3abc1111",
      "fs_id": "FS-PL348847",
      "description": "Auto top-up",
      "method": "Card",
      "credits": "+1",
      "amount": "₹1,499.00",
      "status": "Success",
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));

    // define tabs once so we can create keys
    _tabs = ["All", "Success", "Pending", "Failed", "Refunded"];
    _tabKeys = List.generate(_tabs.length, (_) => GlobalKey());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabScrollController.dispose();
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

    final f = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    final now = DateTime(2025, 12, 25);

    int availableCredits = 0;
    double processed30Days = 0.0;

    for (var t in transactions) {
      final d = _safeParseDateTime(t['date']);
      final cred = int.tryParse(t['credits'].replaceAll('+', '').replaceAll('-', '')) ?? 0;
      final sign = t['credits'].startsWith('-') ? -1 : 1;
      final amt = double.tryParse(t['amount'].replaceAll('₹', '').replaceAll(',', '').replaceAll('-', '')) ?? 0.0;
      final amtSign = t['amount'].startsWith('-') ? -1 : 1;

      if (t['status'] == "Success" || t['status'] == "Refunded") {
        availableCredits += sign * cred;
      }

      final diff = now.difference(d).inDays;
      if (t['status'] == "Success" && diff >= 0 && diff <= 30) {
        processed30Days += amtSign * amt;
      }
    }

    final searchQuery = _searchController.text.toLowerCase();

    var filteredTransactions = transactions.where((t) {
      final matchesSearch = searchQuery.isEmpty ||
          t['invoice'].toString().toLowerCase().contains(searchQuery) ||
          t['fs_id'].toString().toLowerCase().contains(searchQuery) ||
          t['description'].toString().toLowerCase().contains(searchQuery) ||
          t['method'].toString().toLowerCase().contains(searchQuery) ||
          t['status'].toString().toLowerCase().contains(searchQuery);

      final matchesTab = selectedTab == "All" ||
          t['status'] == selectedTab;

      return matchesSearch && matchesTab;
    }).toList()
      ..sort((a, b) => _safeParseDateTime(b['date']).compareTo(_safeParseDateTime(a['date'])));

    return AppLayout(
      title: "USER",
      subtitle: "Transactions",
      actionIcons: const [],
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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3))],
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: "Search invoice, description, method...",
                  hintStyle: GoogleFonts.inter(color: colorScheme.onSurface.withOpacity(0.6), fontSize: bodyFs),
                  prefixIcon: Icon(CupertinoIcons.search, size: iconSize, color: colorScheme.onSurface.withOpacity(0.7)),
                  border: InputBorder.none,
                  focusColor: colorScheme.primary,
                    enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.transparent, width: 0),
                    ),
                    focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                  contentPadding: EdgeInsets.symmetric(horizontal: hp, vertical: hp),
                ),
              ),
            ),
            SizedBox(height: hp),

            // STATS
            Container(
              padding: EdgeInsets.symmetric(vertical: hp),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statBox("Available Credits", availableCredits.toString(), "", bodyFs, smallFs, colorScheme, spacing),
                  _statBox("Processed (30 days)", f.format(processed30Days), "", bodyFs, smallFs, colorScheme, spacing),
                ],
              ),
            ),
            SizedBox(height: hp),

            SizedBox(
              height: hp * 3, // tweak if tabs are clipped
              child: Scrollbar(
                controller: _tabScrollController,
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 1,
                radius: Radius.circular(8),
                child: SingleChildScrollView(
                  controller: _tabScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: spacing),
                  child: Row(
                    children: List.generate(_tabs.length, (index) {
                      final tab = _tabs[index];
                      return Padding(
                        padding: EdgeInsets.only(right: spacing),
                        // ensure we have a context to call ensureVisible on:
                        child: KeyedSubtree(
                          key: _tabKeys[index],
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 5.0),
                            child: SmallTab(
                              label: tab,
                              selected: selectedTab == tab,
                              onTap: () {
                                setState(() => selectedTab = tab);
                            
                                // wait until after frame so the widget exists, then ensure visible
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  final ctx = _tabKeys[index].currentContext;
                                  if (ctx != null) {
                                    Scrollable.ensureVisible(
                                      ctx,
                                      duration: Duration(milliseconds: 300),
                                      alignment: 0.5, // 0.5 tries to center it in view
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: hp),

            // COUNT
            Text(
              "Showing ${filteredTransactions.length} of ${transactions.length} transactions",
              style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface.withOpacity(0.87)),
            ),
            SizedBox(height: spacing * 1.5),

            // TRANSACTION CARDS
            ...filteredTransactions.asMap().entries.map((entry) {
              final index = entry.key;
              final tran = entry.value;

              Color getStatusColor(String status) {
                if (status == "Success") return Colors.green;
                if (status == "Pending") return Colors.orange;
                if (status == "Failed" || status == "Refunded") return Colors.red;
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
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
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
                                    border: Border.all(color: colorScheme.primary.withOpacity(0.6)),
                                  ),
                                  child: Icon(CupertinoIcons.money_dollar_circle, size: AdaptiveUtils.getFsAvatarFontSize(width), color: colorScheme.primary),
                                ),
                                SizedBox(width: spacing * 1.5),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(tran["date"], style: GoogleFonts.inter(fontSize: smallFs, color: colorScheme.onSurface.withOpacity(0.6))),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: spacing + 4, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: getStatusColor(tran["status"]).withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              tran["status"],
                                              style: GoogleFonts.inter(
                                                fontSize: smallFs,
                                                fontWeight: FontWeight.w600,
                                                color: getStatusColor(tran["status"]),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: spacing / 2),
                                      Text(tran["invoice"], style: GoogleFonts.inter(fontSize: bodyFs + 2, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                      SizedBox(height: spacing / 2),
                                      Row(
                                        children: [
                                          Text(tran["fs_id"], style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                          IconButton(
                                            icon: Icon(CupertinoIcons.doc_on_clipboard, size: iconSize - 4, color: colorScheme.primary),
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(text: tran["fs_id"]));
                                            },
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: spacing / 2),
                                      Text(tran["description"], style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                      SizedBox(height: spacing / 2),
                                      Text(tran["method"], style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                      SizedBox(height: spacing / 2),
                                      Row(
                                        children: [
                                          Text("Credits: ${tran["credits"]}", style: GoogleFonts.inter(fontSize: bodyFs - 1, color: colorScheme.onSurface)),
                                          SizedBox(width: spacing),
                                          Text("Amount: ${tran["amount"]}", style: GoogleFonts.inter(fontSize: bodyFs - 1, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: Icon(CupertinoIcons.ellipsis_vertical, color: colorScheme.primary.withOpacity(0.6)),
                                  onSelected: (String value) {
                                    if (value == 'details') {
                                      context.push("/user/transactions/details/${tran['id']}");
                                    } else if (value == 'receipt') {
                                      // empty
                                    } else if (value == 'copy') {
                                      Clipboard.setData(ClipboardData(text: tran["fs_id"]));
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                     PopupMenuItem<String>(
                                      value: 'details',
                                      child: ListTile(
                                        leading: Icon(Icons.visibility, color: colorScheme.primary,),
                                        title: Text('View details'),
                                      ),
                                    ),
                                     PopupMenuItem<String>(
                                      value: 'receipt',
                                      child: ListTile(
                                        leading: Icon(Icons.receipt, color: colorScheme.primary,),
                                        title: Text('Receipt'),
                                      ),
                                    ),
                                     PopupMenuItem<String>(
                                      value: 'copy',
                                      child: ListTile(
                                        leading: Icon(Icons.content_copy, color: colorScheme.primary,),
                                        title: Text('Copy reference'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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

  Widget _statBox(String title, String value, String subtitle, double bodyFs, double smallFs, ColorScheme colorScheme, double spacing) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: spacing / 2),
        child: Column(
          children: [
            Text(title, style: GoogleFonts.inter(fontSize: smallFs, color: colorScheme.onSurface.withOpacity(0.6))),
            Text(value, style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.bold, color: colorScheme.primary.withOpacity(0.5))),
            if (subtitle.isNotEmpty)
              Text(subtitle, style: GoogleFonts.inter(fontSize: smallFs - 1, color: colorScheme.onSurface.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }
}