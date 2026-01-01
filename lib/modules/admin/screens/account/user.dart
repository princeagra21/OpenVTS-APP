
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/adaptive_utils.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  String selectedTab = "All";
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> users = [
    {
      "id": 0,
      "initials": "AS",
      "name": "Aarav Sharma",
      "phone": "+91 981000000",
      "username": "@aarav0",
      "email": "user0@fleetstack.dev",
      "status": "Verified",
      "vehicles": "0",
      "active": true,
      "location": "New Delhi, India",
      "joined": "22 Dec 2025 • 0d",
      "role": "Quantum Logistics • Admin",
    },
    {
      "id": 1,
      "initials": "PS",
      "name": "Priya Singh",
      "phone": "+91 981000137",
      "username": "@priya1",
      "email": "user1@fleetstack.dev",
      "status": "Pending",
      "vehicles": "9",
      "active": true,
      "location": "New Delhi, India",
      "joined": "20 Dec 2025 • 2d",
      "role": "SkyFleet • User",
    },
    {
      "id": 2,
      "initials": "RG",
      "name": "Rohan Gupta",
      "phone": "+91 981000274",
      "username": "@rohan2",
      "email": "user2@fleetstack.dev",
      "status": "Verified",
      "vehicles": "18",
      "active": true,
      "location": "New Delhi, India",
      "joined": "19 Dec 2025 • 3d",
      "role": "RoadStar • User",
    },
    {
      "id": 3,
      "initials": "IV",
      "name": "Isha Verma",
      "phone": "+91 981000411",
      "username": "@isha3",
      "email": "user3@fleetstack.dev",
      "status": "Pending",
      "vehicles": "27",
      "active": true,
      "location": "New Delhi, India",
      "joined": "17 Dec 2025 • 5d",
      "role": "UrbanMove • Admin",
    },
    {
      "id": 4,
      "initials": "AM",
      "name": "Arjun Mehta",
      "phone": "+91 981000548",
      "username": "@arjun4",
      "email": "user4@fleetstack.dev",
      "status": "Verified",
      "vehicles": "36",
      "active": true,
      "location": "New Delhi, India",
      "joined": "15 Dec 2025 • 7d",
      "role": "Vector Wheels • User",
    },
    {
      "id": 5,
      "initials": "AS",
      "name": "Aarav Sharma",
      "phone": "+91 981000685",
      "username": "@aarav5",
      "email": "user5@fleetstack.dev",
      "status": "Pending",
      "vehicles": "45",
      "active": true,
      "location": "New Delhi, India",
      "joined": "13 Dec 2025 • 9d",
      "role": "Quantum Logistics • User",
    },
    {
      "id": 6,
      "initials": "PS",
      "name": "Priya Singh",
      "phone": "+91 981000822",
      "username": "@priya6",
      "email": "user6@fleetstack.dev",
      "status": "Verified",
      "vehicles": "54",
      "active": true,
      "location": "New Delhi, India",
      "joined": "12 Dec 2025 • 10d",
      "role": "SkyFleet • Admin",
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  Future<void> _makePhoneCall(String rawPhone) async {
  // sanitize phone string (remove spaces/parentheses)
  final phone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
  final uri = Uri(scheme: 'tel', path: phone);

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open dialer for $rawPhone')),
      );
    }
  }
}


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // --- ADAPTIVE VALUES ---
    final padding = AdaptiveUtils.getHorizontalPadding(screenWidth); // 8-16
    final spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth); // 6-10
    final titleFs = AdaptiveUtils.getTitleFontSize(screenWidth); // 13-15
    final bodyFs = titleFs - 1; // general text
    final smallFs = titleFs - 3;
    final iconSize = titleFs + 2;
    final cardPadding = padding + 4; // slightly bigger for cards
    final searchQuery = _searchController.text.toLowerCase();

    var filteredUsers = users.where((user) {
      final matchesSearch = searchQuery.isEmpty ||
          user['name'].toString().toLowerCase().contains(searchQuery) ||
          user['phone'].toString().toLowerCase().contains(searchQuery) ||
          user['username'].toString().toLowerCase().contains(searchQuery) ||
          user['email'].toString().toLowerCase().contains(searchQuery) ||
          user['status'].toString().toLowerCase().contains(searchQuery) ||
          user['vehicles'].toString().toLowerCase().contains(searchQuery) ||
          user['location'].toString().toLowerCase().contains(searchQuery) ||
          user['joined'].toString().toLowerCase().contains(searchQuery) ||
          user['role'].toString().toLowerCase().contains(searchQuery);

      final matchesTab = selectedTab == "All" ||
          (selectedTab == "Active" && user['active'] == true) ||
          (selectedTab == "Disabled" && user['active'] == false) ||
          (selectedTab == "Pending" && user['status'] == "Pending");

      return matchesSearch && matchesTab;
    }).toList();

    return AppLayout(
      title: "ADMIN",
      subtitle: "User Management",
      showLeftAvatar: false,
      actionIcons: const [],
      onActionTaps: [],
      leftAvatarText: 'US',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------
            // SEARCH FIELD
            // --------------------------------------------
            Container(
              height: padding * 3.5,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: "Search name, email, role, department...",
                  hintStyle: GoogleFonts.inter(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontSize: bodyFs,
                  ),
                  prefixIcon: Icon(CupertinoIcons.search, size: iconSize, color: colorScheme.primary),
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
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: padding,
                    vertical: padding,
                  ),
                ),
              ),
            ),
            SizedBox(height: padding),
            // --------------------------------------------
            // TABS
            // --------------------------------------------
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: ["All", "Active", "Disabled", "Pending"].map((tab) {
                return SmallTab(
                  label: tab,
                  selected: selectedTab == tab,
                  onTap: () => setState(() => selectedTab = tab),
                );
              }).toList(),
            ),
            SizedBox(height: padding),
            // --------------------------------------------
            // TOP ROW: showing count + add user
            // --------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Showing ${filteredUsers.length} of ${users.length} users",
                  style: GoogleFonts.inter(
                    fontSize: bodyFs,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
                // ADD USER BUTTON
                /*
                GestureDetector(
                  onTap: () {
                    context.push('/admin/users/add');
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: padding * 1.5,
                      vertical: spacing,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
                    ),
                    child: Text(
                      "Add User",
                      style: GoogleFonts.inter(
                        fontSize: bodyFs,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                */
              ],
            ),
            SizedBox(height: spacing),
            // --------------------------------------------
            // USER LIST
            // --------------------------------------------
            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return Container(
                  margin: EdgeInsets.only(bottom: padding),
                  decoration: BoxDecoration(
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
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(25),
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(25),
                      child: Padding(
                        padding: EdgeInsets.all(cardPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // AVATAR
                                CircleAvatar(
                                  backgroundColor: colorScheme.primary,
                                  radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2,
                                  child: Text(
                                    user["initials"],
                                    style: GoogleFonts.inter(
                                      color: colorScheme.onPrimary,
                                      fontSize: AdaptiveUtils.getFsAvatarFontSize(screenWidth),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: spacing * 2),
                                // RIGHT SIDE
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // NAME + STATUS + LOGIN
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                user["name"],
                                                style: GoogleFonts.inter(
                                                  fontSize: bodyFs,
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.onSurface,
                                                ),
                                              ),
                                              SizedBox(width: spacing),
                                              // STATUS BADGE
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: spacing + 2,
                                                  vertical: spacing - 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: user["status"] == "Verified"
                                                      ? Colors.green.withOpacity(0.2)
                                                      : Colors.orange.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: Text(
                                                  user["status"],
                                                  style: GoogleFonts.inter(
                                                    fontSize: smallFs,
                                                    fontWeight: FontWeight.w600,
                                                    color: user["status"] == "Verified"
                                                        ? Colors.green
                                                        : Colors.orange,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          // LOGIN BUTTON
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: padding + 4,
                                              vertical: spacing - 2,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: colorScheme.primary.withOpacity(0.5),
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Text(
                                              "Login",
                                              style: GoogleFonts.inter(
                                                fontSize: smallFs + 1,
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: spacing),
                                      // PHONE
                                      // PHONE with call button
// PHONE with call button
Row(
  children: [
    Icon(
      CupertinoIcons.phone,
      size: iconSize,
      color: colorScheme.primary.withOpacity(0.87),
    ),
    SizedBox(width: spacing),
    Expanded(
      child: Text(
        user["phone"],
        style: GoogleFonts.inter(
          fontSize: bodyFs,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
    ),
    IconButton(
      tooltip: 'Call ${user["name"]}',
      onPressed: () => _makePhoneCall(user['phone'].toString()),
      padding: EdgeInsets.zero,  // Add this
      constraints: BoxConstraints(minWidth: 48, minHeight: iconSize),  // Add this
      icon: Icon(
        Icons.call,
        size: iconSize,
        color: isDark ? colorScheme.primary : Colors.green,
      ),
    ),
  ],
),

                                      SizedBox(height: spacing / 2),
                                      // EMAIL
                                      Row(
                                        children: [
                                          Icon(CupertinoIcons.mail, size: iconSize, color: colorScheme.primary.withOpacity(0.87)),
                                          SizedBox(width: spacing),
                                          Text(
                                            user["email"],
                                            style: GoogleFonts.inter(
                                              fontSize: bodyFs,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: spacing / 2),
                                      // VEHICLES
                                      Row(
                                        children: [
                                          Icon(Icons.directions_car_filled_outlined, size: iconSize, color: colorScheme.primary.withOpacity(0.87)),
                                          SizedBox(width: spacing),
                                          Text(
                                            "${user["vehicles"]} Vehicles",
                                            style: GoogleFonts.inter(
                                              fontSize: bodyFs,
                                              fontWeight: FontWeight.w600,
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
                            SizedBox(height: spacing * 2),
                            // ACTIVE + SWITCH
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Active",
                                  style: GoogleFonts.inter(
                                    fontSize: smallFs + 1,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Transform.scale(
                                  scale: 0.75,
                                  child: Switch(
                                    value: user["active"],
                                    onChanged: (v) {
                                      setState(() => user["active"] = v);
                                    },
                                    activeColor: colorScheme.onPrimary,
                                    activeTrackColor: colorScheme.primary,
                                    inactiveThumbColor: colorScheme.onPrimary,
                                    inactiveTrackColor: colorScheme.primary.withOpacity(0.3),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing),
                            Row(
                              children: [
                                Icon(CupertinoIcons.location, size: iconSize, color: colorScheme.primary.withOpacity(0.87)),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: Text(
                                    user["location"],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing),
                            Divider(color: colorScheme.onSurface.withOpacity(0.1)),
                            SizedBox(height: spacing),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Joined: ${user["joined"]}",
                                    style: GoogleFonts.inter(
                                      fontSize: smallFs,
                                      color: colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    user["role"],
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.inter(
                                      fontSize: smallFs - 1,
                                      color: colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: padding * 2),
          ],
        ),
      ),
    );
  }
}