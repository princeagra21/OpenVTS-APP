// screens/drivers/driver_screen.dart
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/user/layout/app_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  String selectedTab = "All";
  final TextEditingController _searchController = TextEditingController();

  Future<void> _makePhoneCall(String rawPhone) async {
    // Sanitize phone string
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

  final List<Map<String, dynamic>> drivers = [
    {
      "name": "John Smith",
      "mobile": "+1 234-567-8901",
      "vehicle": "Toyota Camry - ABC123",
      "address": "123 Main Street, Downtown",
      "status": "Active",
      "initials": "JS",
    },
    {
      "name": "Sarah Johnson",
      "mobile": "+1 234-567-8902",
      "vehicle": "Honda Civic - XYZ789",
      "address": "456 Oak Avenue, Midtown",
      "status": "Active",
      "initials": "SJ",
    },
    {
      "name": "Mike Davis",
      "mobile": "+1 234-567-8903",
      "vehicle": "Ford Focus - DEF456",
      "address": "789 Pine Road, South Beach",
      "status": "Inactive",
      "initials": "MD",
    },
    {
      "name": "Emma Wilson",
      "mobile": "+1 234-567-8904",
      "vehicle": "Nissan Altima - GHI789",
      "address": "321 Elm Street, Uptown",
      "status": "Active",
      "initials": "EW",
    },
    {
      "name": "Robert Brown",
      "mobile": "+1 234-567-8905",
      "vehicle": "BMW 3 Series - JKL012",
      "address": "654 Birch Lane, Westside",
      "status": "Inactive",
      "initials": "RB",
    },
    {
      "name": "Lisa Martinez",
      "mobile": "+1 234-567-8906",
      "vehicle": "Mercedes C-Class - MNO345",
      "address": "987 Cedar Drive, East End",
      "status": "Active",
      "initials": "LM",
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

    var filteredDrivers = drivers.where((d) {
      final matchesSearch = searchQuery.isEmpty ||
          d['name'].toString().toLowerCase().contains(searchQuery) ||
          d['mobile'].toString().toLowerCase().contains(searchQuery) ||
          d['vehicle'].toString().toLowerCase().contains(searchQuery) ||
          d['address'].toString().toLowerCase().contains(searchQuery);

      final matchesTab = selectedTab == "All" ||
          d['status'].toString() == selectedTab;

      return matchesSearch && matchesTab;
    }).toList()
      ..sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));

    Color getStatusColor(String status) {
      return status == "Active" ? Colors.green : Colors.red;
    }

    return AppLayout(
      title: "USER",
      subtitle: "Drivers Management",
      actionIcons: const [CupertinoIcons.add],
      onActionTaps: [() => context.push("/user/drivers/add")],
      showLeftAvatar: false,
      leftAvatarText: 'DR',
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
                  hintText: "Search name, mobile, vehicle, address...",
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
                  style: GoogleFonts.inter(
                    fontSize: bodyFs,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push("/user/drivers/add"),
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
                      "Add Driver",
                      style: GoogleFonts.inter(
                        fontSize: bodyFs,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 1.5),

            // DRIVER CARDS
            ...filteredDrivers.asMap().entries.map((entry) {
              final index = entry.key;
              final driver = entry.value;
              final statusColor = getStatusColor(driver['status']);

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
                      onTap: () {}, // Navigate to details if needed
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
                                driver['initials'],
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
                                        driver['name'],
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
                                          driver['status'],
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
                                  // MOBILE WITH CALL
                                  Row(
                                    children: [
                                      Icon(
                                        CupertinoIcons.phone,
                                        size: iconSize,
                                        color: colorScheme.primary.withOpacity(0.87),
                                      ),
                                      SizedBox(width: spacing),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _makePhoneCall(driver['mobile']),
                                          child: Text(
                                            driver['mobile'],
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
                                        onPressed: () => _makePhoneCall(driver['mobile']),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: spacing / 2),
                                  // VEHICLE
                                  Row(
                                    children: [
                                      Icon(CupertinoIcons.car_detailed, size: iconSize, color: colorScheme.primary.withOpacity(0.87)),
                                      SizedBox(width: spacing),
                                      Text(
                                        driver['vehicle'],
                                        style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: spacing / 2),
                                  // ADDRESS
                                  Row(
                                    children: [
                                      Icon(CupertinoIcons.location, size: iconSize, color: colorScheme.primary.withOpacity(0.87)),
                                      SizedBox(width: spacing),
                                      Expanded(
                                        child: Text(
                                          driver['address'],
                                          style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface),
                                        ),
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