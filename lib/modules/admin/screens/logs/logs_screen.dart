// screens/logs/logs_screen.dart
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  String selectedTab = "All";
  final TextEditingController _searchController = TextEditingController();

  DateTime _safeParseDateTime(String dateStr) {
    try {
      return DateFormat('dd/MM/yyyy, HH:mm:ss').parse(dateStr);
    } catch (e) {
      return DateTime.now();
    }
  }

  // Sample Logs Data
  final List<Map<String, dynamic>> logs = [
    {
      "time": "25/12/2025, 18:39:02",
      "type": "vehicle",
      "entity": "Tata Ace GJ05KD8821",
      "message": "Geofence exit detected • Warehouse-2",
      "severity": "warning",
      "channel": "system",
    },
    {
      "time": "25/12/2025, 18:32:02",
      "type": "vehicle",
      "entity": "Eicher 14T MH14CX1021",
      "message": "Device offline (48h)",
      "severity": "error",
      "channel": "system",
    },
    {
      "time": "25/12/2025, 18:28:02",
      "type": "vehicle",
      "entity": "Leyland 1618 RJ27Z7402",
      "message": "Overspeed end • Avg 62 km/h",
      "severity": "info",
      "channel": "sms",
    },
    {
      "time": "25/12/2025, 18:26:02",
      "type": "vehicle",
      "entity": "Scorpio N DL09AB2613",
      "message": "Ignition ON",
      "severity": "info",
      "channel": "system",
    },
    {
      "time": "25/12/2025, 18:15:02",
      "type": "vehicle",
      "entity": "Mahindra 4x4 UP32FA4477",
      "message": "Location update",
      "severity": "info",
      "channel": "system",
    },
    {
      "time": "25/12/2025, 18:06:02",
      "type": "vehicle",
      "entity": "Bolero Pickup KA03MP9090",
      "message": "Harsh braking detected",
      "severity": "warning",
      "channel": "system",
    },
    {
      "time": "25/12/2025, 17:41:02",
      "type": "vehicle",
      "entity": "Tata Ace GJ05KD8821",
      "message": "Ignition OFF",
      "severity": "info",
      "channel": "system",
    },
    {
      "time": "25/12/2025, 17:40:02",
      "type": "vehicle",
      "entity": "Eicher 14T MH14CX1021",
      "message": "Device heartbeat",
      "severity": "info",
      "channel": "system",
    },
    {
      "time": "25/12/2025, 17:06:02",
      "type": "vehicle",
      "entity": "Leyland 1618 RJ27Z7402",
      "message": "Tamper detected",
      "severity": "error",
      "channel": "system",
    },
    {
      "time": "25/12/2025, 16:31:02",
      "type": "vehicle",
      "entity": "Mahindra 4x4 UP32FA4477",
      "message": "Long idle: 25m",
      "severity": "warning",
      "channel": "system",
    },
    {
      "time": "25/12/2025, 18:45:02",
      "type": "user",
      "entity": "Admin John",
      "message": "Login successful",
      "severity": "info",
      "channel": "system",
    },
    {
      "time": "25/12/2025, 18:30:02",
      "type": "user",
      "entity": "User Alice",
      "message": "Password reset attempted",
      "severity": "warning",
      "channel": "email",
    },
    {
      "time": "25/12/2025, 18:25:02",
      "type": "user",
      "entity": "Manager Bob",
      "message": "User created",
      "severity": "info",
      "channel": "system",
    },
    {
      "time": "25/12/2025, 18:20:02",
      "type": "user",
      "entity": "User Charlie",
      "message": "Failed login (3 attempts)",
      "severity": "error",
      "channel": "system",
    },
    {
      "time": "25/12/2025, 18:10:02",
      "type": "user",
      "entity": "Admin John",
      "message": "Report generated",
      "severity": "info",
      "channel": "system",
    },
    {
      "time": "25/12/2025, 18:00:02",
      "type": "user",
      "entity": "User Alice",
      "message": "Profile updated",
      "severity": "info",
      "channel": "system",
    },
    {
      "time": "25/12/2025, 17:50:02",
      "type": "user",
      "entity": "Manager Bob",
      "message": "Permission denied",
      "severity": "warning",
      "channel": "system",
    },
    {
      "time": "25/12/2025, 17:30:02",
      "type": "user",
      "entity": "User Charlie",
      "message": "Logout",
      "severity": "info",
      "channel": "system",
    },
    {
      "time": "25/12/2025, 17:00:02",
      "type": "user",
      "entity": "Admin John",
      "message": "System config changed",
      "severity": "warning",
      "channel": "system",
    },
    {
      "time": "25/12/2025, 16:45:02",
      "type": "user",
      "entity": "User Alice",
      "message": "API access error",
      "severity": "error",
      "channel": "system",
    },
    {
      "time": "25/12/2025, 18:40:02",
      "type": "driver",
      "entity": "Driver Raj",
      "message": "Route assigned",
      "severity": "info",
      "channel": "system",
    },
    {
      "time": "25/12/2025, 18:35:02",
      "type": "driver",
      "entity": "Driver Sita",
      "message": "Fatigue detected",
      "severity": "warning",
      "channel": "system",
    },
    {
      "time": "25/12/2025, 18:29:02",
      "type": "driver",
      "entity": "Driver Amit",
      "message": "Check-in at depot",
      "severity": "info",
      "channel": "app",
    },
    {
      "time": "25/12/2025, 18:22:02",
      "type": "driver",
      "entity": "Driver Priya",
      "message": "Overspeed violation",
      "severity": "error",
      "channel": "system",
    },
    {
      "time": "25/12/2025, 18:12:02",
      "type": "driver",
      "entity": "Driver Raj",
      "message": "Break taken",
      "severity": "info",
      "channel": "system",
    },
    {
      "time": "25/12/2025, 18:05:02",
      "type": "driver",
      "entity": "Driver Sita",
      "message": "Route deviation",
      "severity": "warning",
      "channel": "system",
    },
    {
      "time": "25/12/2025, 17:45:02",
      "type": "driver",
      "entity": "Driver Amit",
      "message": "Delivery completed",
      "severity": "info",
      "channel": "app",
    },
    {
      "time": "25/12/2025, 17:35:02",
      "type": "driver",
      "entity": "Driver Priya",
      "message": "Vehicle inspection failed",
      "severity": "error",
      "channel": "system",
    },
    {
      "time": "25/12/2025, 17:10:02",
      "type": "driver",
      "entity": "Driver Raj",
      "message": "Shift started",
      "severity": "info",
      "channel": "system",
    },
    {
      "time": "25/12/2025, 16:40:02",
      "type": "driver",
      "entity": "Driver Sita",
      "message": "Harsh acceleration",
      "severity": "warning",
      "channel": "system",
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

    var filteredLogs = logs.where((log) {
      final matchesSearch = searchQuery.isEmpty ||
          log['time'].toString().toLowerCase().contains(searchQuery) ||
          log['type'].toString().toLowerCase().contains(searchQuery) ||
          log['entity'].toString().toLowerCase().contains(searchQuery) ||
          log['message'].toString().toLowerCase().contains(searchQuery) ||
          log['severity'].toString().toLowerCase().contains(searchQuery) ||
          log['channel'].toString().toLowerCase().contains(searchQuery);

      final matchesTab = selectedTab == "All" ||
          (selectedTab == "Info" && log['severity'] == "info") ||
          (selectedTab == "Warning" && log['severity'] == "warning") ||
          (selectedTab == "Error" && log['severity'] == "error");

      return matchesSearch && matchesTab;
    }).toList()
      ..sort((a, b) => _safeParseDateTime(b['time']).compareTo(_safeParseDateTime(a['time'])));

    return AppLayout(
      title: "ADMIN",
      subtitle: "Logs & Activity",
      actionIcons: const [CupertinoIcons.gear],
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
                  hintText: "Search time, type, entity, message...",
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
              children: ["All", "Info", "Warning", "Error"].map((tab) {
                return SmallTab(
                  label: tab,
                  selected: selectedTab == tab,
                  onTap: () => setState(() => selectedTab = tab),
                );
              }).toList(),
            ),
            SizedBox(height: hp),

            // COUNT
            Text(
              "Showing ${filteredLogs.length} of ${logs.length} logs",
              style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface.withOpacity(0.87)),
            ),
            SizedBox(height: spacing * 1.5),

            // LOG CARDS
            ...filteredLogs.asMap().entries.map((entry) {
              final index = entry.key;
              final log = entry.value;
              Color severityColor = getSeverityColor(log['severity']);

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
                                  child: Icon(
                                    _getIconForType(log['type']),
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
                                          Row(
                                            children: [
                                              Text(log["entity"], style: GoogleFonts.inter(fontSize: bodyFs + 2, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                              SizedBox(width: spacing),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: spacing + 4, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: severityColor.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: Text(
                                                  log["severity"].toUpperCase(),
                                                  style: GoogleFonts.inter(
                                                    fontSize: smallFs,
                                                    fontWeight: FontWeight.w600,
                                                    color: severityColor,
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
                                          Icon(CupertinoIcons.text_bubble, size: iconSize, color: colorScheme.primary.withOpacity(0.6)),
                                          SizedBox(width: spacing),
                                          Text(log["message"], style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                        ],
                                      ),
                                      SizedBox(height: spacing / 2),
                                      Row(
                                        children: [
                                          Icon(CupertinoIcons.device_laptop, size: iconSize, color: colorScheme.primary.withOpacity(0.6)),
                                          SizedBox(width: spacing),
                                          Text(log["channel"], style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                        ],
                                      ),
                                      SizedBox(height: spacing / 2),
                                      Row(
                                        children: [
                                          Icon(CupertinoIcons.tag, size: iconSize, color: colorScheme.primary.withOpacity(0.6)),
                                          SizedBox(width: spacing),
                                          Text(log["type"], style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing * 2),
                            // TIME
                            Text(
                              "Time: ${log["time"]}",
                              style: GoogleFonts.inter(fontSize: smallFs + 1, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.87)),
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

  Color getSeverityColor(String severity) {
    if (severity == "info") return Colors.blue;
    if (severity == "warning") return Colors.orange;
    if (severity == "error") return Colors.red;
    return Colors.grey;
  }

  IconData _getIconForType(String type) {
    if (type == "vehicle") return CupertinoIcons.car;
    if (type == "user") return CupertinoIcons.person;
    if (type == "driver") return CupertinoIcons.person_alt_circle;
    return CupertinoIcons.info;
  }
}