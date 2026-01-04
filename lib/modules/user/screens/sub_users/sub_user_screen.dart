// screens/sub_users/sub_user_screen.dart
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/user/layout/app_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class SubUserScreen extends StatefulWidget {
  const SubUserScreen({super.key});

  @override
  State<SubUserScreen> createState() => _SubUserScreenState();
}

class _SubUserScreenState extends State<SubUserScreen> {
  String selectedTab = "All";
  final TextEditingController _searchController = TextEditingController();

  Future<void> _makePhoneCall(String rawPhone) async {
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

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    final int take = name.length >= 2 ? 2 : name.length;
    return name.substring(0, take).toUpperCase();
  }

  final List<Map<String, dynamic>> subUsers = [
    {
      "name": "Kamal Admin",
      "username": "MEM-MWKDMF",
      "mobile": "+91 9898xxxxxx",
      "email": "kamal@fleetstack.com",
      "permissions": "34 scopes",
      "status": "Active",
    },
    {
      "name": "Riya Ops",
      "username": "MEM-X0M6DQ",
      "mobile": "+91 9090xxxxxx",
      "email": "riya@fleetstack.com",
      "permissions": "20 scopes",
      "status": "Active",
    },
    {
      "name": "Aman Support",
      "username": "MEM-WP2IA5",
      "mobile": "+91 9797xxxxxx",
      "email": "aman@fleetstack.com",
      "permissions": "10 scopes",
      "status": "Disabled",
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final searchQuery = _searchController.text.toLowerCase();

    var filteredSubUsers = subUsers.where((u) {
      final matchesSearch = searchQuery.isEmpty ||
          u['name'].toString().toLowerCase().contains(searchQuery) ||
          u['username'].toString().toLowerCase().contains(searchQuery) ||
          u['mobile'].toString().toLowerCase().contains(searchQuery) ||
          u['email'].toString().toLowerCase().contains(searchQuery) ||
          u['permissions'].toString().toLowerCase().contains(searchQuery);

      final matchesTab = selectedTab == "All" ||
          u['status'].toString() == selectedTab;

      return matchesSearch && matchesTab;
    }).toList()
      ..sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));

    Color getStatusColor(String status) {
      return status == "Active" ? Colors.green : Colors.red;
    }

    return AppLayout(
      title: "USER",
      subtitle: "Sub-users",
      actionIcons: const [CupertinoIcons.add],
     // onActionTaps: [() => context.push("/user/sub-users/add")],
      showLeftAvatar: false,
      leftAvatarText: 'SU',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SEARCH BAR
            Container(
              height: hp * 3.5,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: "Search name, username, mobile, email...",
                  hintStyle: GoogleFonts.inter(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontSize: bodyFs,
                  ),
                  prefixIcon: Icon(CupertinoIcons.search, size: iconSize, color: colorScheme.primary),
                  border: InputBorder.none,
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
                  "Showing ${filteredSubUsers.length} of ${subUsers.length} sub-users",
                  style: GoogleFonts.inter(
                    fontSize: bodyFs,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
                /*
                GestureDetector(
                  onTap: () => context.push("/user/sub-users/add"),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: hp * 1.5,
                      vertical: spacing,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
                    ),
                    child: Text(
                      "Add Sub User",
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
            SizedBox(height: spacing * 1.5),

            // SUB USER CARDS
            ...filteredSubUsers.asMap().entries.map((entry) {
              final index = entry.key;
              final subUser = entry.value;
              final statusColor = getStatusColor(subUser['status']);
              final initials = _getInitials(subUser['name']);

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
                      )
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: () {}, // Navigate to details/edit if needed
                      child: Padding(
                        padding: EdgeInsets.all(cardPadding),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // AVATAR
                            CircleAvatar(
                              radius: AdaptiveUtils.getAvatarSize(width) / 2,
                              backgroundColor: colorScheme.primary,
                              child: Text(
                                initials,
                                style: GoogleFonts.inter(
                                  fontSize: AdaptiveUtils.getFsAvatarFontSize(width),
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            SizedBox(width: spacing * 1.5),
                            // MAIN INFO
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        subUser['name'],
                                        style: GoogleFonts.inter(
                                          fontSize: bodyFs + 2,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: spacing + 4, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          subUser['status'],
                                          style: GoogleFonts.inter(
                                            fontSize: smallFs + 1,
                                            fontWeight: FontWeight.w600,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: spacing),
                                  // USERNAME
                                  Row(
                                    children: [
                                      Icon(CupertinoIcons.person_crop_circle, size: iconSize, color: colorScheme.primary.withOpacity(0.87)),
                                      SizedBox(width: spacing),
                                      Text(
                                        subUser['username'],
                                        style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: spacing / 2),
                                  // MOBILE WITH CALL
                                  Row(
                                    children: [
                                      Icon(CupertinoIcons.phone, size: iconSize, color: colorScheme.primary.withOpacity(0.87)),
                                      SizedBox(width: spacing),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _makePhoneCall(subUser['mobile']),
                                          child: Text(
                                            "kamal${subUser['mobile']}", // Prepend name part if needed, adjust as per data
                                            style: GoogleFonts.inter(
                                              fontSize: bodyFs,
                                              color: colorScheme.primary,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.call, size: iconSize, color: isDark ? colorScheme.primary : Colors.green),
                                        onPressed: () => _makePhoneCall(subUser['mobile']),
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
                                        subUser['email'],
                                        style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: spacing / 2),
                                  // PERMISSIONS
                                  Row(
                                    children: [
                                      Icon(CupertinoIcons.shield, size: iconSize, color: colorScheme.primary.withOpacity(0.87)),
                                      SizedBox(width: spacing),
                                      Text(
                                        subUser['permissions'],
                                        style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface),
                                      ),
                                    ],
                                  ),
                                ],
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
}