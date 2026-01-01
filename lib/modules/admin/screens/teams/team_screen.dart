// screens/teams/team_screen.dart
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  String selectedTab = "All";
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> members = [
    {
      "id": 0,
      "name": "Kamal Admin",
      "member_id": "MEM-0JIJ9I",
      "username": "kamal",
      "mobile": "+91 9898xxxxxx",
      "email": "kamal@fleetstack.com",
      "permissions": "34 scopes",
      "status": "Active",
      "enabled": true,
    },
    {
      "id": 1,
      "name": "Riya Ops",
      "member_id": "MEM-Z9BOD3",
      "username": "riya.ops",
      "mobile": "+91 9090xxxxxx",
      "email": "riya@fleetstack.com",
      "permissions": "20 scopes",
      "status": "Active",
      "enabled": true,
    },
    {
      "id": 2,
      "name": "Aman Support",
      "member_id": "MEM-VP4W1S",
      "username": "aman",
      "mobile": "+91 9797xxxxxx",
      "email": "aman@fleetstack.com",
      "permissions": "10 scopes",
      "status": "Disabled",
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

    var filteredMembers = members.where((m) {
      final matchesSearch = searchQuery.isEmpty ||
          m['name'].toString().toLowerCase().contains(searchQuery) ||
          m['username'].toString().toLowerCase().contains(searchQuery) ||
          m['mobile'].toString().toLowerCase().contains(searchQuery) ||
          m['email'].toString().toLowerCase().contains(searchQuery) ||
          m['permissions'].toString().toLowerCase().contains(searchQuery);

      final matchesTab = selectedTab == "All" ||
          (selectedTab == "Active" && m['status'] == "Active") ||
          (selectedTab == "Disabled" && m['status'] == "Disabled");

      return matchesSearch && matchesTab;
    }).toList()
      ..sort((a, b) => a['name'].compareTo(b['name']));

    return AppLayout(
      title: "ADMIN",
      subtitle: "Teams Management",
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
                  hintText: "Search name, username, mobile, email...",
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
              children: ["All", "Active", "Disabled"].map((tab) {
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
                  "Showing ${filteredMembers.length} of ${members.length} members",
                  style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface.withOpacity(0.87)),
                ),
                GestureDetector(
                  onTap: () => context.push("/admin/teams/add"),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: hp * 1.5, vertical: spacing),
                    decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).colorScheme.primary)),
                    child: Text(
                      "Add Team",
                      style: GoogleFonts.inter(fontSize: bodyFs - 3, fontWeight: FontWeight.w600, color: colorScheme.primary),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 1.5),

            // MEMBER CARDS
            ...filteredMembers.asMap().entries.map((entry) {
              final index = entry.key;
              final member = entry.value;

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
                                  child: Icon(CupertinoIcons.person, size: AdaptiveUtils.getFsAvatarFontSize(width), color: colorScheme.primary),
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
                                              Text(member["name"], style: GoogleFonts.inter(fontSize: bodyFs + 2, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                              SizedBox(width: spacing),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: spacing + 4, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: member["status"] == "Active" ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: Text(
                                                  member["status"].toUpperCase(),
                                                  style: GoogleFonts.inter(
                                                    fontSize: smallFs,
                                                    fontWeight: FontWeight.w600,
                                                    color: member["status"] == "Active" ? Colors.green : Colors.red,
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
                                          Icon(CupertinoIcons.tag, size: iconSize, color: colorScheme.primary.withOpacity(0.6)),
                                          SizedBox(width: spacing),
                                          Text("Member ID: ${member["member_id"]}", style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                        ],
                                      ),
                                      SizedBox(height: spacing / 2),
                                      Row(
                                        children: [
                                          Icon(CupertinoIcons.at, size: iconSize, color: colorScheme.primary.withOpacity(0.6)),
                                          SizedBox(width: spacing),
                                          Text(member["username"], style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                        ],
                                      ),
                                      SizedBox(height: spacing / 2),
                                      Row(
                                        children: [
                                          Icon(CupertinoIcons.phone, size: iconSize, color: colorScheme.primary.withOpacity(0.6)),
                                          SizedBox(width: spacing),
                                          Text(member["mobile"], style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                        ],
                                      ),
                                      SizedBox(height: spacing / 2),
                                      Row(
                                        children: [
                                          Icon(CupertinoIcons.mail, size: iconSize, color: colorScheme.primary.withOpacity(0.6)),
                                          SizedBox(width: spacing),
                                          Text(member["email"], style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                        ],
                                      ),
                                      SizedBox(height: spacing / 2),
                                      Row(
                                        children: [
                                          Icon(CupertinoIcons.lock_shield, size: iconSize, color: colorScheme.primary.withOpacity(0.6)),
                                          SizedBox(width: spacing),
                                          Text(member["permissions"], style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing * 2),
                            // SWITCH
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Transform.scale(
                                  scale: 0.85,
                                  child: Switch(
                                    value: member["enabled"],
                                    activeColor: colorScheme.onPrimary,
                                    activeTrackColor: colorScheme.primary,
                                    inactiveThumbColor: colorScheme.onSurfaceVariant,
                                    inactiveTrackColor: colorScheme.surfaceVariant,
                                    onChanged: (v) => setState(() {
                                      member["enabled"] = v;
                                      member["status"] = v ? "Active" : "Disabled";
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