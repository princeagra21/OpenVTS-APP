// screens/drivers/driver_screen.dart
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  String selectedTab = "All";
  final TextEditingController _searchController = TextEditingController();

  DateTime _safeParseDateTime(String dateStr, {bool hasTime = true}) {
    try {
      String format = hasTime ? 'dd MMM hh:mma yyyy' : 'd MMM yyyy';
      String fullStr = hasTime ? '$dateStr 2025' : dateStr;
      return DateFormat(format).parse(fullStr);
    } catch (e) {
      try {
        return DateTime.parse(dateStr);
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  final List<Map<String, dynamic>> drivers = [
    {
      "id": 0,
      "name": "David Brown",
      "username": "@davidb",
      "phone": "+91 9876543214",
      "email": "david.brown@example.com",
      "address": "654 T. Nagar, Chennai, TN, IN",
      "status": "Active",
      "last_activity": "22 Dec 07:09PM",
      "initials": "DB",
      "expiry": "9 Dec 2025",
      "enabled": true,
    },
    {
      "id": 1,
      "name": "Jane Smith",
      "username": "@janesmith",
      "phone": "+91 9876543211",
      "email": "jane.smith@example.com",
      "address": "456 Andheri East, Mumbai, MH, IN",
      "status": "Active",
      "last_activity": "22 Dec 09:27PM",
      "initials": "JS",
      "expiry": "9 Dec 2025",
      "enabled": true,
    },
    {
      "id": 2,
      "name": "John Doe",
      "username": "@johndoe",
      "phone": "+91 9876543210",
      "email": "john.doe@example.com",
      "address": "123 MG Road, Lucknow, UP, IN",
      "status": "Active",
      "last_activity": "22 Dec 06:06PM",
      "initials": "JD",
      "expiry": "17 Oct 2027",
      "enabled": true,
    },
    {
      "id": 3,
      "name": "Michael Johnson",
      "username": "@michaelj",
      "phone": "+91 9876543212",
      "email": "michael.johnson@example.com",
      "address": "789 Koramangala, Bangalore, KA, IN",
      "status": "Inactive",
      "last_activity": "22 Dec 08:15PM",
      "initials": "MJ",
      "expiry": "12 Nov 2027",
      "enabled": false,
    },
    {
      "id": 4,
      "name": "Sarah Wilson",
      "username": "@sarahw",
      "phone": "+91 9876543213",
      "email": "sarah.wilson@example.com",
      "address": "321 Connaught Place, Delhi, DL, IN",
      "status": "Active",
      "last_activity": "22 Dec 05:33PM",
      "initials": "SW",
      "expiry": "5 Dec 2027",
      "enabled": true,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final double titleFs = AdaptiveUtils.getTitleFontSize(width);
    final double bodyFs = titleFs - 1;
    final double smallFs = titleFs - 3;
    final double iconSize = titleFs + 2;
    final double cardPadding = hp + 4;

    final searchQuery = _searchController.text.toLowerCase();

    var filteredDrivers = drivers.where((d) {
      final matchesSearch = searchQuery.isEmpty ||
          d['name'].toString().toLowerCase().contains(searchQuery) ||
          d['username'].toString().toLowerCase().contains(searchQuery) ||
          d['phone'].toString().toLowerCase().contains(searchQuery) ||
          d['email'].toString().toLowerCase().contains(searchQuery) ||
          d['address'].toString().toLowerCase().contains(searchQuery);

      final matchesTab = selectedTab == "All" ||
          (selectedTab == "Active" && d['status'] == "Active") ||
          (selectedTab == "Inactive" && d['status'] == "Inactive");

      return matchesSearch && matchesTab;
    }).toList()
      ..sort((a, b) => _safeParseDateTime(b['last_activity']).compareTo(_safeParseDateTime(a['last_activity'])));

    return AppLayout(
      title: "ADMIN",
      subtitle: "Drivers Management",
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
                  hintText: "Search name, username, phone, email...",
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
              children: ["All", "Active", "Inactive"].map((tab) {
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
                  "Showing ${filteredDrivers.length} of ${drivers.length} drivers",
                  style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface.withOpacity(0.87)),
                ),
                /*
                GestureDetector(
                  onTap: () => context.push("/admin/drivers/add"),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: hp * 1.5, vertical: spacing),
                    decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).colorScheme.primary)),
                    child: Text(
                      "Add Driver",
                      style: GoogleFonts.inter(fontSize: bodyFs - 3, fontWeight: FontWeight.w600, color: colorScheme.primary),
                    ),
                  ),
                ),
                */
              ],
            ),
            SizedBox(height: spacing * 1.5),

            // DRIVER CARDS
            ...filteredDrivers.asMap().entries.map((entry) {
              final index = entry.key;
              final driver = entry.value;

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
                                              Text(driver["name"], style: GoogleFonts.inter(fontSize: bodyFs + 2, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                              SizedBox(width: spacing),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: spacing + 4, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: driver["status"] == "Active" ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: Text(
                                                  driver["status"].toUpperCase(),
                                                  style: GoogleFonts.inter(
                                                    fontSize: smallFs,
                                                    fontWeight: FontWeight.w600,
                                                    color: driver["status"] == "Active" ? Colors.green : Colors.red,
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
                                          Icon(CupertinoIcons.at, size: iconSize, color: colorScheme.primary.withOpacity(0.6)),
                                          SizedBox(width: spacing),
                                          Text(driver["username"], style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                        ],
                                      ),
                                      SizedBox(height: spacing / 2),
                                     // PHONE with call button
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
        driver["phone"],
        style: GoogleFonts.inter(
          fontSize: bodyFs,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
    ),
    IconButton(
      tooltip: 'Call ${driver["name"]}',
      onPressed: () => _makePhoneCall(driver['phone'].toString()),
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
                                      Row(
                                        children: [
                                          Icon(CupertinoIcons.mail, size: iconSize, color: colorScheme.primary.withOpacity(0.6)),
                                          SizedBox(width: spacing),
                                          Text(driver["email"], style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                        ],
                                      ),
                                      SizedBox(height: spacing / 2),
                                      Row(
                                        children: [
                                          Icon(CupertinoIcons.location, size: iconSize, color: colorScheme.primary.withOpacity(0.6)),
                                          SizedBox(width: spacing),
                                          Text(driver["address"], style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing * 2),
                            // LAST SEEN + SWITCH
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Last Activity: ${driver["last_activity"]}",
                                  style: GoogleFonts.inter(fontSize: smallFs + 1, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.87)),
                                ),
                                Transform.scale(
                                  scale: 0.85,
                                  child: Switch(
                                    value: driver["enabled"],
                                    activeColor: colorScheme.onPrimary,
                                    activeTrackColor: colorScheme.primary,
                                    inactiveThumbColor: colorScheme.onSurfaceVariant,
                                    inactiveTrackColor: colorScheme.surfaceVariant,
                                    onChanged: (v) => setState(() {
                                      driver["enabled"] = v;
                                    }),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing),
                            Divider(color: colorScheme.outline.withOpacity(0.3)),
                            SizedBox(height: spacing),
                            Text(
                              "Expiry: ${driver["expiry"]}",
                              style: GoogleFonts.inter(fontSize: smallFs, color: colorScheme.onSurface.withOpacity(0.54)),
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