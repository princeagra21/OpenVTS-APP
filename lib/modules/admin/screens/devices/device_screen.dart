// screens/devices/device_screen.dart
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
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

  final List<Map<String, dynamic>> devices = [
    {
      "id": 0,
      "imei": "123456789012345",
      "type": "GPS Tracker",
      "sim": "+1234567890",
      "provider": "Verizon",
      "status": "Active",
      "expiry": "15/01/2024",
      "enabled": true,
    },
    {
      "id": 1,
      "imei": "234567890123456",
      "type": "Vehicle Tracker",
      "sim": "+2345678901",
      "provider": "AT&T",
      "status": "Active",
      "expiry": "16/01/2024",
      "enabled": true,
    },
    {
      "id": 2,
      "imei": "345678901234567",
      "type": "Asset Tracker",
      "sim": "No SIM",
      "provider": "-",
      "status": "Inactive",
      "expiry": "17/01/2024",
      "enabled": false,
    },
    {
      "id": 3,
      "imei": "456789012345678",
      "type": "OBD Tracker",
      "sim": "+3456789012",
      "provider": "T-Mobile",
      "status": "Maintenance",
      "expiry": "18/01/2024",
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

    var filteredDevices = devices.where((d) {
      final matchesSearch = searchQuery.isEmpty ||
          d['imei'].toString().toLowerCase().contains(searchQuery) ||
          d['type'].toString().toLowerCase().contains(searchQuery) ||
          d['sim'].toString().toLowerCase().contains(searchQuery) ||
          d['provider'].toString().toLowerCase().contains(searchQuery);

      final matchesTab = selectedTab == "All" ||
          (selectedTab == "Active" && d['status'] == "Active") ||
          (selectedTab == "Maintenance" && d['status'] == "Maintenance") ||
          (selectedTab == "Inactive" && d['status'] == "Inactive");

      return matchesSearch && matchesTab;
    }).toList()
      ..sort((a, b) => _safeParseDateTime(b['expiry']).compareTo(_safeParseDateTime(a['expiry'])));

    return AppLayout(
      title: "ADMIN",
      subtitle: "Devices Management",
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
                  hintText: "Search IMEI, type, SIM, provider...",
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
              children: ["All", "Active", "Maintenance", "Inactive"].map((tab) {
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
                  "Showing ${filteredDevices.length} of ${devices.length} devices",
                  style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface.withOpacity(0.87)),
                ),
                GestureDetector(
                  onTap: () => context.push("/admin/devices/add"),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: hp * 1.5, vertical: spacing),
                    decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).colorScheme.primary)),
                    child: Text(
                      "Add Device",
                      style: GoogleFonts.inter(fontSize: bodyFs - 3, fontWeight: FontWeight.w600, color: colorScheme.primary),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 1.5),

            // DEVICE CARDS
            ...filteredDevices.asMap().entries.map((entry) {
              final index = entry.key;
              final device = entry.value;

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
                                  child: Icon(CupertinoIcons.device_laptop, size: AdaptiveUtils.getFsAvatarFontSize(width), color: colorScheme.primary),
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
                                              Text(device["imei"], style: GoogleFonts.inter(fontSize: bodyFs + 2, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                              SizedBox(width: spacing),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: spacing + 4, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: device["status"] == "Active" ? Colors.green.withOpacity(0.15) : (device["status"] == "Maintenance" ? Colors.orange.withOpacity(0.15) : Colors.red.withOpacity(0.15)),
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: Text(
                                                  device["status"],
                                                  style: GoogleFonts.inter(
                                                    fontSize: smallFs,
                                                    fontWeight: FontWeight.w600,
                                                    color: device["status"] == "Active" ? Colors.green : (device["status"] == "Maintenance" ? Colors.orange : Colors.red),
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
                                          Icon(CupertinoIcons.device_phone_portrait, size: iconSize, color: colorScheme.primary.withOpacity(0.6)),
                                          SizedBox(width: spacing),
                                          Text(device["type"], style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                        ],
                                      ),
                                      SizedBox(height: spacing / 2),
                                      Row(
                                        children: [
                                          Icon(Icons.sim_card, size: iconSize, color: colorScheme.primary.withOpacity(0.6)),
                                          SizedBox(width: spacing),
                                          Text(device["sim"], style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                        ],
                                      ),
                                      SizedBox(height: spacing / 2),
                                      Row(
                                        children: [
                                          Icon(CupertinoIcons.globe, size: iconSize, color: colorScheme.primary.withOpacity(0.6)),
                                          SizedBox(width: spacing),
                                          Text(device["provider"], style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
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
                                  "Expiry: ${device["expiry"]}",
                                  style: GoogleFonts.inter(fontSize: smallFs + 1, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.87)),
                                ),
                                Transform.scale(
                                  scale: 0.85,
                                  child: Switch(
                                    value: device["enabled"],
                                    activeColor: colorScheme.onPrimary,
                                    activeTrackColor: colorScheme.primary,
                                    inactiveThumbColor: colorScheme.onSurfaceVariant,
                                    inactiveTrackColor: colorScheme.surfaceVariant,
                                    onChanged: (v) => setState(() {
                                      device["enabled"] = v;
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