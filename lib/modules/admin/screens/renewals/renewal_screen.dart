// screens/renewals/renewals_screen.dart
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class RenewalsScreen extends StatefulWidget {
  const RenewalsScreen({super.key});

  @override
  State<RenewalsScreen> createState() => _RenewalsScreenState();
}

class _RenewalsScreenState extends State<RenewalsScreen> with SingleTickerProviderStateMixin {
  late TabController _parentTabController;
  String selectedSubTab = "All";
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _customerTabScrollController = ScrollController();
  final ScrollController _deviceTabScrollController = ScrollController();
  late final List<GlobalKey> _customerTabKeys;
  late final List<GlobalKey> _deviceTabKeys;

  final DateTime currentDate = DateTime(2025, 12, 25);

  DateTime _safeParseDate(String dateStr) {
    try {
      return DateFormat('d MMM yyyy').parse(dateStr);
    } catch (e) {
      return currentDate;
    }
  }

  final List<Map<String, dynamic>> renewals = [
    {
      "customer": "Sharma Logistics",
      "vehicle": "MH12AB1234",
      "imei": "86348204027900",
      "plan": "Annual Basic",
      "amount": "₹1,499.00",
      "installed": "25 Nov 2025",
      "start": "25 Nov 2025",
      "expiry": "25 Nov 2026",
      "days_left": "335 days left",
      "status": "Suspended",
      "auto": true,
    },
    {
      "customer": "Vijay Transports",
      "vehicle": "GJ06CD4567",
      "imei": "86348204027901",
      "plan": "Annual Pro",
      "amount": "₹2,499.00",
      "installed": "25 Oct 2025",
      "start": "25 Oct 2025",
      "expiry": "25 Oct 2026",
      "days_left": "304 days left",
      "status": "Active",
      "auto": false,
    },
    {
      "customer": "RapidMove Co.",
      "vehicle": "DL01EF9876",
      "imei": "86348204027902",
      "plan": "Half-Year Basic",
      "amount": "₹899.00",
      "installed": "25 Sept 2025",
      "start": "25 Sept 2025",
      "expiry": "25 Mar 2026",
      "days_left": "90 days left",
      "status": "Active",
      "auto": false,
    },
    {
      "customer": "NorthStar Fleet",
      "vehicle": "UP14GH2222",
      "imei": "86348204027903",
      "plan": "Quarterly",
      "amount": "₹499.00",
      "installed": "25 Aug 2025",
      "start": "25 Aug 2025",
      "expiry": "25 Nov 2025",
      "days_left": "30 days overdue",
      "status": "Overdue",
      "auto": false,
    },
    {
      "customer": "Kiran Carriers",
      "vehicle": "KA05JK7654",
      "imei": "86348204027904",
      "plan": "Annual Basic",
      "amount": "₹1,499.00",
      "installed": "25 Jul 2025",
      "start": "25 Jul 2025",
      "expiry": "25 Jul 2026",
      "days_left": "212 days left",
      "status": "Active",
      "auto": true,
    },
    {
      "customer": "Sharma Logistics",
      "vehicle": "MH12AB1234",
      "imei": "86348204027905",
      "plan": "Annual Pro",
      "amount": "₹2,499.00",
      "installed": "25 Jun 2025",
      "start": "25 Jun 2025",
      "expiry": "25 Jun 2026",
      "days_left": "182 days left",
      "status": "Active",
      "auto": false,
    },
    {
      "customer": "Vijay Transports",
      "vehicle": "GJ06CD4567",
      "imei": "86348204027906",
      "plan": "Half-Year Basic",
      "amount": "₹899.00",
      "installed": "25 May 2025",
      "start": "25 May 2025",
      "expiry": "25 Nov 2025",
      "days_left": "30 days overdue",
      "status": "Overdue",
      "auto": false,
    },
    {
      "customer": "RapidMove Co.",
      "vehicle": "DL01EF9876",
      "imei": "86348204027907",
      "plan": "Quarterly",
      "amount": "₹499.00",
      "installed": "25 Apr 2025",
      "start": "25 Apr 2025",
      "expiry": "25 Jul 2025",
      "days_left": "153 days overdue",
      "status": "Overdue",
      "auto": false,
    },
    {
      "customer": "NorthStar Fleet",
      "vehicle": "UP14GH2222",
      "imei": "86348204027908",
      "plan": "Annual Basic",
      "amount": "₹1,499.00",
      "installed": "25 Mar 2025",
      "start": "25 Mar 2025",
      "expiry": "25 Mar 2026",
      "days_left": "90 days left",
      "status": "Active",
      "auto": true,
    },
    {
      "customer": "Kiran Carriers",
      "vehicle": "KA05JK7654",
      "imei": "86348204027909",
      "plan": "Annual Pro",
      "amount": "₹2,499.00",
      "installed": "25 Feb 2025",
      "start": "25 Feb 2025",
      "expiry": "25 Feb 2026",
      "days_left": "62 days left",
      "status": "Active",
      "auto": false,
    },
    {
      "customer": "Sharma Logistics",
      "vehicle": "MH12AB1234",
      "imei": "86348204027910",
      "plan": "Half-Year Basic",
      "amount": "₹899.00",
      "installed": "25 Jan 2025",
      "start": "25 Jan 2025",
      "expiry": "25 Jul 2025",
      "days_left": "153 days overdue",
      "status": "Overdue",
      "auto": false,
    },
    {
      "customer": "Vijay Transports",
      "vehicle": "GJ06CD4567",
      "imei": "86348204027911",
      "plan": "Quarterly",
      "amount": "₹499.00",
      "installed": "25 Dec 2024",
      "start": "25 Dec 2024",
      "expiry": "25 Mar 2025",
      "days_left": "275 days overdue",
      "status": "Overdue",
      "auto": false,
    },
    {
      "customer": "RapidMove Co.",
      "vehicle": "DL01EF9876",
      "imei": "86348204027912",
      "plan": "Annual Basic",
      "amount": "₹1,499.00",
      "installed": "25 Nov 2024",
      "start": "25 Nov 2024",
      "expiry": "25 Nov 2025",
      "days_left": "30 days overdue",
      "status": "Overdue",
      "auto": true,
    },
    {
      "customer": "NorthStar Fleet",
      "vehicle": "UP14GH2222",
      "imei": "86348204027913",
      "plan": "Annual Pro",
      "amount": "₹2,499.00",
      "installed": "25 Oct 2024",
      "start": "25 Oct 2024",
      "expiry": "25 Oct 2025",
      "days_left": "61 days overdue",
      "status": "Overdue",
      "auto": false,
    },
    {
      "customer": "Kiran Carriers",
      "vehicle": "KA05JK7654",
      "imei": "86348204027914",
      "plan": "Half-Year Basic",
      "amount": "₹899.00",
      "installed": "25 Sept 2024",
      "start": "25 Sept 2024",
      "expiry": "25 Mar 2025",
      "days_left": "275 days overdue",
      "status": "Overdue",
      "auto": false,
    },
    {
      "customer": "Sharma Logistics",
      "vehicle": "MH12AB1234",
      "imei": "86348204027915",
      "plan": "Quarterly",
      "amount": "₹499.00",
      "installed": "25 Aug 2024",
      "start": "25 Aug 2024",
      "expiry": "25 Nov 2024",
      "days_left": "395 days overdue",
      "status": "Overdue",
      "auto": false,
    },
    {
      "customer": "Vijay Transports",
      "vehicle": "GJ06CD4567",
      "imei": "86348204027916",
      "plan": "Annual Basic",
      "amount": "₹1,499.00",
      "installed": "25 Nov 2025",
      "start": "25 Nov 2025",
      "expiry": "25 Nov 2026",
      "days_left": "335 days left",
      "status": "Active",
      "auto": true,
    },
    {
      "customer": "RapidMove Co.",
      "vehicle": "DL01EF9876",
      "imei": "86348204027917",
      "plan": "Annual Pro",
      "amount": "₹2,499.00",
      "installed": "25 Oct 2025",
      "start": "25 Oct 2025",
      "expiry": "25 Oct 2026",
      "days_left": "304 days left",
      "status": "Suspended",
      "auto": false,
    },
    {
      "customer": "NorthStar Fleet",
      "vehicle": "UP14GH2222",
      "imei": "86348204027918",
      "plan": "Half-Year Basic",
      "amount": "₹899.00",
      "installed": "25 Sept 2025",
      "start": "25 Sept 2025",
      "expiry": "25 Mar 2026",
      "days_left": "90 days left",
      "status": "Active",
      "auto": false,
    },
    {
      "customer": "Kiran Carriers",
      "vehicle": "KA05JK7654",
      "imei": "86348204027919",
      "plan": "Quarterly",
      "amount": "₹499.00",
      "installed": "25 Aug 2025",
      "start": "25 Aug 2025",
      "expiry": "25 Nov 2025",
      "days_left": "30 days overdue",
      "status": "Overdue",
      "auto": false,
    },
    {
      "customer": "Sharma Logistics",
      "vehicle": "MH12AB1234",
      "imei": "86348204027920",
      "plan": "Annual Basic",
      "amount": "₹1,499.00",
      "installed": "25 Jul 2025",
      "start": "25 Jul 2025",
      "expiry": "25 Jul 2026",
      "days_left": "212 days left",
      "status": "Active",
      "auto": true,
    },
    {
      "customer": "Vijay Transports",
      "vehicle": "GJ06CD4567",
      "imei": "86348204027921",
      "plan": "Annual Pro",
      "amount": "₹2,499.00",
      "installed": "25 Jun 2025",
      "start": "25 Jun 2025",
      "expiry": "25 Jun 2026",
      "days_left": "182 days left",
      "status": "Active",
      "auto": false,
    },
    {
      "customer": "RapidMove Co.",
      "vehicle": "DL01EF9876",
      "imei": "86348204027922",
      "plan": "Half-Year Basic",
      "amount": "₹899.00",
      "installed": "25 May 2025",
      "start": "25 May 2025",
      "expiry": "25 Nov 2025",
      "days_left": "30 days overdue",
      "status": "Overdue",
      "auto": false,
    },
    {
      "customer": "NorthStar Fleet",
      "vehicle": "UP14GH2222",
      "imei": "86348204027923",
      "plan": "Quarterly",
      "amount": "₹499.00",
      "installed": "25 Apr 2025",
      "start": "25 Apr 2025",
      "expiry": "25 Jul 2025",
      "days_left": "153 days overdue",
      "status": "Overdue",
      "auto": false,
    },
    {
      "customer": "Kiran Carriers",
      "vehicle": "KA05JK7654",
      "imei": "86348204027924",
      "plan": "Annual Basic",
      "amount": "₹1,499.00",
      "installed": "25 Mar 2025",
      "start": "25 Mar 2025",
      "expiry": "25 Mar 2026",
      "days_left": "90 days left",
      "status": "Active",
      "auto": true,
    },
    {
      "customer": "Sharma Logistics",
      "vehicle": "MH12AB1234",
      "imei": "86348204027925",
      "plan": "Annual Pro",
      "amount": "₹2,499.00",
      "installed": "25 Feb 2025",
      "start": "25 Feb 2025",
      "expiry": "25 Feb 2026",
      "days_left": "62 days left",
      "status": "Active",
      "auto": false,
    },
    {
      "customer": "Vijay Transports",
      "vehicle": "GJ06CD4567",
      "imei": "86348204027926",
      "plan": "Half-Year Basic",
      "amount": "₹899.00",
      "installed": "25 Jan 2025",
      "start": "25 Jan 2025",
      "expiry": "25 Jul 2025",
      "days_left": "153 days overdue",
      "status": "Overdue",
      "auto": false,
    },
    {
      "customer": "RapidMove Co.",
      "vehicle": "DL01EF9876",
      "imei": "86348204027927",
      "plan": "Quarterly",
      "amount": "₹499.00",
      "installed": "25 Dec 2024",
      "start": "25 Dec 2024",
      "expiry": "25 Mar 2025",
      "days_left": "275 days overdue",
      "status": "Overdue",
      "auto": false,
    },
    {
      "customer": "NorthStar Fleet",
      "vehicle": "UP14GH2222",
      "imei": "86348204027928",
      "plan": "Annual Basic",
      "amount": "₹1,499.00",
      "installed": "25 Nov 2024",
      "start": "25 Nov 2024",
      "expiry": "25 Nov 2025",
      "days_left": "30 days overdue",
      "status": "Overdue",
      "auto": true,
    },
    {
      "customer": "Kiran Carriers",
      "vehicle": "KA05JK7654",
      "imei": "86348204027929",
      "plan": "Annual Pro",
      "amount": "₹2,499.00",
      "installed": "25 Oct 2024",
      "start": "25 Oct 2024",
      "expiry": "25 Oct 2025",
      "days_left": "61 days overdue",
      "status": "Overdue",
      "auto": false,
    },
    {
      "customer": "Sharma Logistics",
      "vehicle": "MH12AB1234",
      "imei": "86348204027930",
      "plan": "Half-Year Basic",
      "amount": "₹899.00",
      "installed": "25 Sept 2024",
      "start": "25 Sept 2024",
      "expiry": "25 Mar 2025",
      "days_left": "275 days overdue",
      "status": "Overdue",
      "auto": false,
    },
    {
      "customer": "Vijay Transports",
      "vehicle": "GJ06CD4567",
      "imei": "86348204027931",
      "plan": "Quarterly",
      "amount": "₹499.00",
      "installed": "25 Aug 2024",
      "start": "25 Aug 2024",
      "expiry": "25 Nov 2024",
      "days_left": "395 days overdue",
      "status": "Overdue",
      "auto": false,
    },
    {
      "customer": "RapidMove Co.",
      "vehicle": "DL01EF9876",
      "imei": "86348204027932",
      "plan": "Annual Basic",
      "amount": "₹1,499.00",
      "installed": "25 Nov 2025",
      "start": "25 Nov 2025",
      "expiry": "25 Nov 2026",
      "days_left": "335 days left",
      "status": "Active",
      "auto": true,
    },
    {
      "customer": "NorthStar Fleet",
      "vehicle": "UP14GH2222",
      "imei": "86348204027933",
      "plan": "Annual Pro",
      "amount": "₹2,499.00",
      "installed": "25 Oct 2025",
      "start": "25 Oct 2025",
      "expiry": "25 Oct 2026",
      "days_left": "304 days left",
      "status": "Active",
      "auto": false,
    },
    {
      "customer": "Kiran Carriers",
      "vehicle": "KA05JK7654",
      "imei": "86348204027934",
      "plan": "Half-Year Basic",
      "amount": "₹899.00",
      "installed": "25 Sept 2025",
      "start": "25 Sept 2025",
      "expiry": "25 Mar 2026",
      "days_left": "90 days left",
      "status": "Suspended",
      "auto": false,
    },
    {
      "customer": "Sharma Logistics",
      "vehicle": "MH12AB1234",
      "imei": "86348204027935",
      "plan": "Quarterly",
      "amount": "₹499.00",
      "installed": "25 Aug 2025",
      "start": "25 Aug 2025",
      "expiry": "25 Nov 2025",
      "days_left": "30 days overdue",
      "status": "Overdue",
      "auto": false,
    },
  ];

  List<Map<String, dynamic>> get customers {
    Map<String, Map<String, dynamic>> customerMap = {};
    for (var r in renewals) {
      String cust = r['customer'];
      if (!customerMap.containsKey(cust)) {
        customerMap[cust] = {
          "name": cust,
          "devices": 0,
          "expiring": 0,
          "overdue": 0,
          "suspended": 0,
          "amount": 0.0,
        };
      }
      customerMap[cust]!["devices"] += 1;
      double amt = double.parse(r['amount'].replaceAll('₹', '').replaceAll(',', ''));
      customerMap[cust]!["amount"] += amt;
      if (r['status'] == "Suspended") customerMap[cust]!["suspended"] += 1;
      if (r['status'] == "Overdue") customerMap[cust]!["overdue"] += 1;
      DateTime expiry = _safeParseDate(r['expiry']);
      int days = expiry.difference(currentDate).inDays;
      if (days > 0 && days < 30) customerMap[cust]!["expiring"] += 1;
    }
    return customerMap.values.toList();
  }

  int paymentsToday = 4;
  int expiring = 0;
  int overdue = 0;
  int suspended = 0;
  int active = 0;
  double mrr = 48564.00;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _parentTabController = TabController(length: 2, vsync: this);
    _customerTabKeys = List.generate(5, (_) => GlobalKey());
    _deviceTabKeys = List.generate(5, (_) => GlobalKey());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customerTabScrollController.dispose();
    _deviceTabScrollController.dispose();
    _parentTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height; // Added for height calculation
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final double titleFs = AdaptiveUtils.getTitleFontSize(width);
    final double bodyFs = titleFs - 1;
    final double smallFs = titleFs - 3;
    final double iconSize = titleFs + 2;
    final double cardPadding = hp + 4;

    final f = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    // Calculate overall stats
    expiring = renewals.where((r) {
      DateTime expiry = _safeParseDate(r['expiry']);
      int days = expiry.difference(currentDate).inDays;
      return r['status'] == "Active" && days > 0 && days < 30;
    }).length;
    overdue = renewals.where((r) => r['status'] == "Overdue").length;
    suspended = renewals.where((r) => r['status'] == "Suspended").length;
    active = renewals.where((r) => r['status'] == "Active").length;

    final custList = customers;
    final int allCustCount = custList.length;
    final int activeCustCount = custList.where((c) => c['overdue'] == 0 && c['suspended'] == 0).length;
    final int expiringCustCount = custList.where((c) => c['expiring'] > 0).length;
    final int overdueCustCount = custList.where((c) => c['overdue'] > 0).length;
    final int suspendedCustCount = custList.where((c) => c['suspended'] > 0).length;

    final List<String> subTabs = ["All", "Active", "Expiring", "Overdue", "Suspended"];
    final List<String> custTabLabels = [
      "All ($allCustCount)",
      "Active ($activeCustCount)",
      "Expiring ($expiringCustCount)",
      "Overdue ($overdueCustCount)",
      "Suspended ($suspendedCustCount)",
    ];

    final List<String> deviceTabLabels = [
      "All (${renewals.length})",
      "Active ($active)",
      "Expiring ($expiring)",
      "Overdue ($overdue)",
      "Suspended ($suspended)",
    ];

    return AppLayout(
      title: "ADMIN",
      subtitle: "Renewals & Billing",
      actionIcons: const [CupertinoIcons.add],
      showLeftAvatar: false,
      leftAvatarText: 'SA',
      child: Column(
        children: [
           // SEARCH BAR (moved to top)
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
                hintText: "Search customer, vehicle, IMEI, plan...",
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
          // STATS SECTION

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
                    _statBox("Payments Today", paymentsToday.toString(), "Completed renewals", bodyFs, smallFs, colorScheme, spacing),
                    _statBox("Expiring (<30 days)", expiring.toString(), "Act early", bodyFs, smallFs, colorScheme, spacing),
                  ],
                ),
                SizedBox(height: hp / 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statBox("Overdue", overdue.toString(), "Suspension risk", bodyFs, smallFs, colorScheme, spacing),
                    _statBox("MRR (est.)", f.format(mrr), "From active plans", bodyFs, smallFs, colorScheme, spacing),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: hp),

         

          // TABS SECTION
          TabBar(
            controller: _parentTabController,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
            indicatorColor: colorScheme.primary,
            tabs: const [
              Tab(text: "Customers"),
              Tab(text: "Devices"),
            ],
          ),

          // THE FIX: Wrap TabBarView in a SizedBox with a defined height.
          // We use height * 0.7 to give it enough space to show the lists.
          SizedBox(
            height: height * 0.8, 
            child: TabBarView(
              controller: _parentTabController,
              children: [
                _buildCustomersView(
                  bodyFs, smallFs, colorScheme, spacing, hp, cardPadding,
                  iconSize, custList, subTabs, custTabLabels, f,
                ),
                _buildDevicesView(
                  bodyFs, smallFs, colorScheme, spacing, hp, cardPadding,
                  iconSize, subTabs, deviceTabLabels, f,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersView(
    double bodyFs,
    double smallFs,
    ColorScheme colorScheme,
    double spacing,
    double hp,
    double cardPadding,
    double iconSize,
    List<Map<String, dynamic>> custList,
    List<String> subTabs,
    List<String> tabLabels,
    NumberFormat f,
  ) {
    final searchQuery = _searchController.text.toLowerCase();
    final double width = MediaQuery.of(context).size.width;

    var filteredCustomers = custList.where((c) {
      switch (selectedSubTab) {
        case "All": return true;
        case "Active": return c['overdue'] == 0 && c['suspended'] == 0;
        case "Expiring": return c['expiring'] > 0;
        case "Overdue": return c['overdue'] > 0;
        case "Suspended": return c['suspended'] > 0;
        default: return true;
      }
    }).where((c) {
      return searchQuery.isEmpty || c['name'].toLowerCase().contains(searchQuery);
    }).toList()
      ..sort((a, b) => a['name'].compareTo(b['name']));

    return SingleChildScrollView(
      padding: EdgeInsets.only(top: hp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SUB TABS
          SizedBox(
            height: hp * 3.2,
            child: Scrollbar(
              controller: _customerTabScrollController,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 1,
              radius: Radius.circular(8),
              child: SingleChildScrollView(
                controller: _customerTabScrollController,
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: spacing),
                child: Row(
                  children: List.generate(subTabs.length, (index) {
                    final tab = subTabs[index];
                    return Padding(
                      padding: EdgeInsets.only(right: spacing, bottom: 8),
                      child: KeyedSubtree(
                        key: _customerTabKeys[index],
                        child: SmallTab(
                          label: tabLabels[index],
                          selected: selectedSubTab == tab,
                          onTap: () {
                            setState(() => selectedSubTab = tab);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              final ctx = _customerTabKeys[index].currentContext;
                              if (ctx != null) {
                                Scrollable.ensureVisible(ctx, duration: Duration(milliseconds: 300), alignment: 0.5, curve: Curves.easeInOut);
                              }
                            });
                          },
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          SizedBox(height: hp),

          Text(
            "Showing ${filteredCustomers.length} of ${custList.length} customers",
            style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface.withOpacity(0.87)),
          ),
          SizedBox(height: spacing * 1.5),

          // CUSTOMER CARDS
          ...filteredCustomers.asMap().entries.map((entry) {
            final index = entry.key;
            final cust = entry.value;
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: AdaptiveUtils.getAvatarSize(width),
                            height: AdaptiveUtils.getAvatarSize(width),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                            ),
                            child: Icon(
                              CupertinoIcons.person_2,
                              size: AdaptiveUtils.getFsAvatarFontSize(width),
                              color: colorScheme.primary,
                            ),
                          ),
                          SizedBox(width: spacing * 1.5),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cust["name"],
                                  style: GoogleFonts.inter(fontSize: bodyFs + 2, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                ),
                                SizedBox(height: spacing / 2),
                                Text(
                                  "${cust["devices"]} devices",
                                  style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                                ),
                                SizedBox(height: spacing / 2),
                                Text(
                                  "${cust["expiring"]} expiring • ${cust["overdue"]} overdue • ${cust["suspended"]} suspended",
                                  style: GoogleFonts.inter(fontSize: bodyFs - 1, color: colorScheme.onSurface.withOpacity(0.6)),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            f.format(cust["amount"]),
                            style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.bold, color: colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
          SizedBox(height: hp * 5), // Added extra space for scroll comfort
        ],
      ),
    );
  }

  Widget _buildDevicesView(
    double bodyFs,
    double smallFs,
    ColorScheme colorScheme,
    double spacing,
    double hp,
    double cardPadding,
    double iconSize,
    List<String> subTabs,
    List<String> tabLabels,
    NumberFormat f,
  ) {
    final searchQuery = _searchController.text.toLowerCase();
    final double width = MediaQuery.of(context).size.width;

    var filteredRenewals = renewals.where((r) {
      DateTime expiry = _safeParseDate(r['expiry']);
      int days = expiry.difference(currentDate).inDays;
      switch (selectedSubTab) {
        case "All": return true;
        case "Active": return r['status'] == "Active";
        case "Expiring": return r['status'] == "Active" && days > 0 && days < 30;
        case "Overdue": return r['status'] == "Overdue";
        case "Suspended": return r['status'] == "Suspended";
        default: return true;
      }
    }).where((r) {
      return searchQuery.isEmpty ||
          r['customer'].toLowerCase().contains(searchQuery) ||
          r['vehicle'].toLowerCase().contains(searchQuery) ||
          r['imei'].toLowerCase().contains(searchQuery) ||
          r['plan'].toLowerCase().contains(searchQuery);
    }).toList()
      ..sort((a, b) {
        int daysA = _safeParseDate(a['expiry']).difference(currentDate).inDays;
        int daysB = _safeParseDate(b['expiry']).difference(currentDate).inDays;
        return daysA.compareTo(daysB);
      });

    return SingleChildScrollView(
      padding: EdgeInsets.only(top: hp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SUB TABS
          SizedBox(
            height: hp * 3.2,
            child: Scrollbar(
              controller: _deviceTabScrollController,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 1,
              radius: Radius.circular(8),
              child: SingleChildScrollView(
                controller: _deviceTabScrollController,
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: spacing),
                child: Row(
                  children: List.generate(subTabs.length, (index) {
                    final tab = subTabs[index];
                    return Padding(
                      padding: EdgeInsets.only(right: spacing, bottom: 8),
                      child: KeyedSubtree(
                        key: _deviceTabKeys[index],
                        child: SmallTab(
                          label: tabLabels[index],
                          selected: selectedSubTab == tab,
                          onTap: () {
                            setState(() => selectedSubTab = tab);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              final ctx = _deviceTabKeys[index].currentContext;
                              if (ctx != null) {
                                Scrollable.ensureVisible(ctx, duration: Duration(milliseconds: 300), alignment: 0.5, curve: Curves.easeInOut);
                              }
                            });
                          },
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          SizedBox(height: hp),

          Text(
            "Showing ${filteredRenewals.length} of ${renewals.length} devices",
            style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface.withOpacity(0.87)),
          ),
          SizedBox(height: spacing * 1.5),

          // DEVICE CARDS
          ...filteredRenewals.asMap().entries.map((entry) {
            final index = entry.key;
            final r = entry.value;
            DateTime expiry = _safeParseDate(r['expiry']);
            int days = expiry.difference(currentDate).inDays;
            String daysStr = days > 0 ? "$days days left" : "${-days} days overdue";
            Color statusColor = getStatusColor(r['status']);

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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: AdaptiveUtils.getAvatarSize(width),
                            height: AdaptiveUtils.getAvatarSize(width),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                            ),
                            child: Icon(
                              CupertinoIcons.antenna_radiowaves_left_right,
                              size: AdaptiveUtils.getFsAvatarFontSize(width),
                              color: colorScheme.primary,
                            ),
                          ),
                          SizedBox(width: spacing * 1.5),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(r["expiry"], style: GoogleFonts.inter(fontSize: smallFs, color: colorScheme.onSurface.withOpacity(0.6))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                                      child: Text(r["status"], style: GoogleFonts.inter(fontSize: smallFs, fontWeight: FontWeight.w600, color: statusColor)),
                                    ),
                                  ],
                                ),
                                SizedBox(height: spacing / 2),
                                Text(r["customer"], style: GoogleFonts.inter(fontSize: bodyFs + 2, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                SizedBox(height: spacing / 2),
                                Text(r["vehicle"], style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                SizedBox(height: spacing / 2),
                                Row(
                                  children: [
                                    Text(r["imei"], style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                    IconButton(
                                      icon: Icon(CupertinoIcons.doc_on_clipboard, size: iconSize - 4, color: colorScheme.primary),
                                      onPressed: () => Clipboard.setData(ClipboardData(text: r["imei"])),
                                    ),
                                  ],
                                ),
                                SizedBox(height: spacing / 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(r["plan"], style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                    Text(r["amount"], style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                  ],
                                ),
                                SizedBox(height: spacing / 2),
                                Text("Installed: ${r["installed"]}", style: GoogleFonts.inter(fontSize: smallFs, color: colorScheme.onSurface)),
                                Text("Start: ${r["start"]}", style: GoogleFonts.inter(fontSize: smallFs, color: colorScheme.onSurface)),
                                SizedBox(height: spacing / 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(daysStr, style: GoogleFonts.inter(fontSize: bodyFs - 1, color: statusColor)),
                                    Row(
                                      children: [
                                        Text("Auto Renew", style: GoogleFonts.inter(fontSize: bodyFs - 1, color: colorScheme.onSurface)),
                                        Switch(value: r["auto"], onChanged: (v) => setState(() => r["auto"] = v)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(CupertinoIcons.ellipsis_vertical, color: colorScheme.primary.withOpacity(0.6)),
                            onSelected: (String value) {
  final List<Map<String, dynamic>> selectedDevices = [r];

  switch (value) {
    case 'renew':
      context.push('/admin/renewals/renew', extra: selectedDevices);
      break;
    case 'collect':
      context.push('/admin/renewals/collect', extra: selectedDevices);
      break;
    case 'extend':
      context.push('/admin/renewals/extend', extra: selectedDevices);
      break;
    case 'suspend':
      context.push('/admin/renewals/suspend', extra: selectedDevices);
      break;
    case 'reminder':
      context.push('/admin/renewals/reminder', extra: selectedDevices);
      
      break;
  }
},
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                               PopupMenuItem<String>(
                                value: 'renew',
                                child: ListTile(
                                  leading: Icon(Icons.payment_outlined, color: colorScheme.primary),
                                  title: Text('Renew/Pay'),
                                ),
                              ),
                               PopupMenuItem<String>(
                                value: 'collect',
                                child: ListTile(
                                  leading: Icon(Icons.receipt_outlined, color: colorScheme.primary,),
                                  title: Text('Collect Payment'),
                                ),
                              ),
                               PopupMenuItem<String>(
                                value: 'extend',
                                child: ListTile(
                                  leading: Icon(Icons.timelapse_outlined, color: colorScheme.primary),
                                  title: Text('Extend License'),
                                ),
                              ),
                               PopupMenuItem<String>(
                                value: 'suspend',
                                child: ListTile(
                                  leading: Icon(Icons.pause_circle_outline, color: colorScheme.primary),
                                  title: Text('Suspend'),
                                ),
                              ),
                               PopupMenuItem<String>(
                                value: 'reminder',
                                child: ListTile(
                                  leading: Icon(Icons.notifications_outlined, color: colorScheme.primary),
                                  title: Text('Send Reminder'),
                                ),
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
          SizedBox(height: hp * 5),
        ],
      ),
    );
  }

  Color getStatusColor(String status) {
    if (status == "Active") return Colors.green;
    if (status == "Overdue") return Colors.orange;
    if (status == "Suspended") return Colors.red;
    return Colors.grey;
  }

  Widget _statBox(String title, String value, String subtitle, double bodyFs, double smallFs, ColorScheme colorScheme, double spacing) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: spacing / 2),
        child: Column(
          children: [
            Text(title, style: GoogleFonts.inter(fontSize: smallFs, color: colorScheme.onSurface.withOpacity(0.6))),
            Text(value, style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.bold, color: colorScheme.primary.withOpacity(0.5))),
            Text(subtitle, style: GoogleFonts.inter(fontSize: smallFs - 1, color: colorScheme.onSurface.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }
}