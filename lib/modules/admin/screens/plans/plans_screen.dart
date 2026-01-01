// screens/plans/plans_screen.dart
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  String selectedTab = "All";
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _tabScrollController = ScrollController();
  late final List<String> _tabs;
  late final List<GlobalKey> _tabKeys;

  final List<Map<String, dynamic>> plans = [
    {
      "id": 0,
      "name": "Annual Basic",
      "description": "Essential tracking",
      "price": "₹1,499.00",
      "duration": "365 days",
      "status": "Active",
    },
    {
      "id": 1,
      "name": "Annual Pro",
      "description": "Priority support + reports",
      "price": "₹2,499.00",
      "duration": "365 days",
      "status": "Active",
    },
    {
      "id": 2,
      "name": "Quarterly",
      "description": "Short term",
      "price": "₹699.00",
      "duration": "90 days",
      "status": "Archived",
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));

    // define tabs once so we can create keys
    _tabs = ["All", "Active", "Archived"];
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

    final searchQuery = _searchController.text.toLowerCase();

    var filteredPlans = plans.where((p) {
      final matchesSearch = searchQuery.isEmpty ||
          p['name'].toString().toLowerCase().contains(searchQuery) ||
          p['description'].toString().toLowerCase().contains(searchQuery) ||
          p['price'].toString().toLowerCase().contains(searchQuery) ||
          p['duration'].toString().toLowerCase().contains(searchQuery) ||
          p['status'].toString().toLowerCase().contains(searchQuery);

      final matchesTab = selectedTab == "All" ||
          p['status'] == selectedTab;

      return matchesSearch && matchesTab;
    }).toList()
      ..sort((a, b) => a['name'].compareTo(b['name']));

    return AppLayout(
      title: "ADMIN",
      subtitle: "Plans",
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
                  hintText: "Search plan name, description, price...",
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

            // COUNT + ADD BUTTON
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Showing ${filteredPlans.length} of ${plans.length} plans",
                  style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface.withOpacity(0.87)),
                ),
                GestureDetector(
                  onTap: () => context.push("/admin/plans/add"),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: hp * 1.5, vertical: spacing),
                    decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: colorScheme.primary, width: 1.5)),
                    child: Text(
                      "Add Plan",
                      style: GoogleFonts.inter(fontSize: bodyFs - 3, fontWeight: FontWeight.w600, color: colorScheme.onPrimary),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 1.5),

            // PLAN CARDS
            ...filteredPlans.asMap().entries.map((entry) {
              final index = entry.key;
              final plan = entry.value;

              Color getStatusColor(String status) {
                if (status == "Active") return Colors.green;
                if (status == "Archived") return Colors.red;
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
                                  child: Icon(CupertinoIcons.doc_text, size: AdaptiveUtils.getFsAvatarFontSize(width), color: colorScheme.primary),
                                ),
                                SizedBox(width: spacing * 1.5),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(plan["name"], style: GoogleFonts.inter(fontSize: bodyFs + 2, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: spacing + 4, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: getStatusColor(plan["status"]).withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              plan["status"],
                                              style: GoogleFonts.inter(
                                                fontSize: smallFs,
                                                fontWeight: FontWeight.w600,
                                                color: getStatusColor(plan["status"]),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: spacing / 2),
                                      Text(plan["description"], style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                      SizedBox(height: spacing / 2),
                                      Text("Price: ${plan["price"]}", style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                      SizedBox(height: spacing / 2),
                                      Text("Duration: ${plan["duration"]}", style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: Icon(CupertinoIcons.ellipsis_vertical, color: colorScheme.primary.withOpacity(0.6)),
                                  onSelected: (String value) {
                                    if (value == 'edit') {
                                      context.push("/admin/plans/edit/${plan['id']}", extra: plan);
                                    } else if (value == 'archive') {
                                      // archive logic
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'edit',
                                      child: ListTile(
                                        leading: Icon(Icons.edit_outlined),
                                        title: Text('Edit'),
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'archive',
                                      child: ListTile(
                                        leading: Icon(Icons.archive_outlined),
                                        title: Text('Archive'),
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
}