// screens/sims/sim_screen.dart
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SimScreen extends StatefulWidget {
  const SimScreen({super.key});

  @override
  State<SimScreen> createState() => _SimScreenState();
}

class _SimScreenState extends State<SimScreen> {
  String selectedTab = "All";
  final TextEditingController _searchController = TextEditingController();

  DateTime _safeParseDateTime(String dateStr) {
    try {
      return DateFormat('dd/MM/yyyy').parse(dateStr);
    } catch (e) {
      try {
        return DateTime.parse(dateStr);
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  final List<Map<String, dynamic>> sims = [
    {
      "id": 0,
      "phone": "0987654321",
      "provider": "Airtel",
      "device_imei": "987654321098765",
      "iccid": "89987654321098765432",
      "status": "Inactive",
      "expiry": "14/01/2024",
      "enabled": false,
    },
    {
      "id": 1,
      "phone": "1234567890",
      "provider": "Vodafone",
      "device_imei": "123456789012345",
      "iccid": "89012345678901234567",
      "status": "Active",
      "expiry": "15/01/2024",
      "enabled": true,
    },
    {
      "id": 2,
      "phone": "5555666677",
      "provider": "Jio",
      "device_imei": "-",
      "iccid": "-",
      "status": "Suspended",
      "expiry": "13/01/2024",
      "enabled": false,
    },
  ];

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

    final searchQuery = _searchController.text.toLowerCase();

    var filteredSims = sims.where((s) {
      final matchesSearch = searchQuery.isEmpty ||
          s['phone'].toString().toLowerCase().contains(searchQuery) ||
          s['provider'].toString().toLowerCase().contains(searchQuery) ||
          s['device_imei'].toString().toLowerCase().contains(searchQuery) ||
          s['iccid'].toString().toLowerCase().contains(searchQuery);

      final matchesTab = selectedTab == "All" ||
          (selectedTab == "Active" && s['status'] == "Active") ||
          (selectedTab == "Inactive" && s['status'] == "Inactive") ||
          (selectedTab == "Suspended" && s['status'] == "Suspended");

      return matchesSearch && matchesTab;
    }).toList()
      ..sort((a, b) => _safeParseDateTime(b['expiry']).compareTo(_safeParseDateTime(a['expiry'])));

    return AppLayout(
      title: "ADMIN",
      subtitle: "SIM Cards Management",
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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3))],
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: "Search phone, provider, IMEI, ICCID...",
                  hintStyle: GoogleFonts.inter(color: colorScheme.onSurface.withOpacity(0.6), fontSize: bodyFs),
                  prefixIcon: Icon(CupertinoIcons.search, size: iconSize, color: colorScheme.primary.withOpacity(0.7)),
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

            // TABS
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: ["All", "Active", "Inactive", "Suspended"].map((tab) {
                return SmallTab(
                  label: tab,
                  selected: selectedTab == tab,
                  onTap: () => setState(() => selectedTab = tab),
                );
              }).toList(),
            ),
            SizedBox(height: hp),

            // COUNT + ADD BUTTON
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Showing ${filteredSims.length} of ${sims.length} SIM cards",
                  style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface.withOpacity(0.87)),
                ),
                GestureDetector(
                  onTap: () => context.push("/admin/sims/add"),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: hp * 1.5, vertical: spacing),
                    decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: colorScheme.primary, width: 1)),
                    child: Text(
                      "Add SIM Card",
                      style: GoogleFonts.inter(fontSize: bodyFs - 3, fontWeight: FontWeight.w600, color: colorScheme.primary),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 1.5),

            // SIM CARDS
            ...filteredSims.asMap().entries.map((entry) {
              final index = entry.key;
              final sim = entry.value;

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
                                    border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                                  ),
                                  child: Icon(Icons.sim_card, size: AdaptiveUtils.getFsAvatarFontSize(width), color: colorScheme.primary),
                                ),
                                SizedBox(width: spacing * 1.5),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text(sim["phone"], style: GoogleFonts.inter(fontSize: bodyFs + 2, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                              SizedBox(width: spacing),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: spacing + 4, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: sim["status"] == "Active" ? Colors.green.withOpacity(0.15) : (sim["status"] == "Suspended" ? Colors.orange.withOpacity(0.15) : Colors.red.withOpacity(0.15)),
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: Text(
                                                  sim["status"],
                                                  style: GoogleFonts.inter(
                                                    fontSize: smallFs,
                                                    fontWeight: FontWeight.w600,
                                                    color: sim["status"] == "Active" ? Colors.green : (sim["status"] == "Suspended" ? Colors.orange : Colors.red),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: spacing / 2),
                                      Row(
                                        children: [
                                          Icon(CupertinoIcons.globe, size: iconSize, color: colorScheme.primary.withOpacity(0.6)),
                                          SizedBox(width: spacing),
                                          Text(sim["provider"], style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                        ],
                                      ),
                                      SizedBox(height: spacing / 2),
                                      Row(
                                        children: [
                                          Icon(CupertinoIcons.device_laptop, size: iconSize, color: colorScheme.primary.withOpacity(0.6)),
                                          SizedBox(width: spacing),
                                          Text("IMEI: ${sim["device_imei"]}", style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                        ],
                                      ),
                                      SizedBox(height: spacing / 2),
                                      Row(
                                        children: [
                                          Icon(CupertinoIcons.tag, size: iconSize, color: colorScheme.primary.withOpacity(0.6)),
                                          SizedBox(width: spacing),
                                          Text("ICCID: ${sim["iccid"]}", style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing * 2),
                            // EXPIRY + SWITCH
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Expiry: ${sim["expiry"]}",
                                  style: GoogleFonts.inter(fontSize: smallFs + 1, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.87)),
                                ),
                                Transform.scale(
                                  scale: 0.85,
                                  child: Switch(
                                    value: sim["enabled"],
                                    activeColor: colorScheme.onPrimary,
                                    activeTrackColor: colorScheme.primary,
                                    inactiveThumbColor: colorScheme.onSurfaceVariant,
                                    inactiveTrackColor: colorScheme.surfaceVariant,
                                    onChanged: (v) => setState(() {
                                      sim["enabled"] = v;
                                    }),
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

            SizedBox(height: hp * 3),
          ],
        ),
      ),
    );
  }
}