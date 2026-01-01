// screens/vehicles/vehicle_screen.dart
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
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

  final List<Map<String, dynamic>> vehicles = [
    {
      "id": 0,
      "model": "Ashok Leyland 4000XL #04",
      "imei": "365859021048097",
      "vin": "YBLCYP0V147FS57DE",
      "motion": "RUNNING",
      "duration": "3h 50m",
      "speed": "88km/h",
      "last_activity": "22 Dec 07:09PM",
      "initials": "AK",
      "name": "Aanya Khan",
      "expiry": "9 Dec 2025",
      "enabled": true,
      "ignition": true,
      "gps": true,
      "locked": true,
    },
    {
      "id": 1,
      "model": "Ashok Leyland Ace #18",
      "imei": "543316123438161",
      "vin": "VNDXGEVGS3TB7NYLD",
      "motion": "RUNNING",
      "duration": "3h 17m",
      "speed": "38km/h",
      "last_activity": "22 Dec 09:27PM",
      "initials": "IV",
      "name": "Isha Verma",
      "expiry": "9 Dec 2025",
      "enabled": true,
      "ignition": true,
      "gps": true,
      "locked": true,
    },
    {
      "id": 2,
      "model": "Ashok Leyland Ace #39",
      "imei": "037511543933158",
      "vin": "HX2VGHPK3W72NB3RX",
      "motion": "RUNNING",
      "duration": "0h 54m",
      "speed": "12km/h",
      "last_activity": "22 Dec 06:06PM",
      "initials": "MK",
      "name": "Mira Khan",
      "expiry": "17 Oct 2027",
      "enabled": true,
      "ignition": true,
      "gps": true,
      "locked": true,
    },
    {
      "id": 3,
      "model": "Ashok Leyland Bolero #20",
      "imei": "250623010204931",
      "vin": "G13R9XUGS5XJ44SYC",
      "motion": "RUNNING",
      "duration": "3h 0m",
      "speed": "84km/h",
      "last_activity": "22 Dec 08:15PM",
      "initials": "MI",
      "name": "Mira Iyer",
      "expiry": "12 Nov 2027",
      "enabled": true,
      "ignition": true,
      "gps": true,
      "locked": true,
    },
    {
      "id": 4,
      "model": "Ashok Leyland Bolero #34",
      "imei": "902966568006996",
      "vin": "NXMYRR4AXK8X55VHV",
      "motion": "RUNNING",
      "duration": "2h 42m",
      "speed": "75km/h",
      "last_activity": "22 Dec 05:33PM",
      "initials": "AP",
      "name": "Arjun Patel",
      "expiry": "5 Dec 2027",
      "enabled": true,
      "ignition": true,
      "gps": true,
      "locked": true,
    },
    {
      "id": 5,
      "model": "Ashok Leyland Bolero #50",
      "imei": "514953645205108",
      "vin": "3UWT8BW30A3KE6UPN",
      "motion": "STOPPED",
      "duration": "4h 38m",
      "speed": "60km/h",
      "last_activity": "22 Dec 06:19PM",
      "initials": "AN",
      "name": "Arjun Nair",
      "expiry": "15 Nov 2026",
      "enabled": true,
      "ignition": false,
      "gps": true,
      "locked": true,
    },
    {
      "id": 6,
      "model": "Ashok Leyland Intra #40",
      "imei": "286918269145627",
      "vin": "J677L9HLJTSNTDDL0",
      "motion": "STOPPED",
      "duration": "0h 29m",
      "speed": "81km/h",
      "last_activity": "22 Dec 05:48PM",
      "initials": "DP",
      "name": "Diya Patel",
      "expiry": "27 Dec 2025",
      "enabled": true,
      "ignition": false,
      "gps": true,
      "locked": true,
    },
    {
      "id": 7,
      "model": "Ashok Leyland Pro 3015 #28",
      "imei": "594524637216868",
      "vin": "U8GGSMAAR9NHYBHYE",
      "motion": "RUNNING",
      "duration": "0h 42m",
      "speed": "38km/h",
      "last_activity": "22 Dec 07:49PM",
      "initials": "KI",
      "name": "Kabir Iyer",
      "expiry": "28 Nov 2025",
      "enabled": true,
      "ignition": true,
      "gps": true,
      "locked": true,
    },
    {
      "id": 8,
      "model": "Ashok Leyland XUV700 #09",
      "imei": "793252438741596",
      "vin": "RJLMRKF348MB35AC7",
      "motion": "RUNNING",
      "duration": "1h 18m",
      "speed": "3km/h",
      "last_activity": "22 Dec 07:35PM",
      "initials": "AI",
      "name": "Aarav Iyer",
      "expiry": "11 Oct 2026",
      "enabled": true,
      "ignition": true,
      "gps": true,
      "locked": true,
    },
    {
      "id": 9,
      "model": "Eicher 4000XL #03",
      "imei": "429121575103195",
      "vin": "5PFDM4NUTEB5WD7B2",
      "motion": "RUNNING",
      "duration": "3h 43m",
      "speed": "35km/h",
      "last_activity": "22 Dec 06:33PM",
      "initials": "AV",
      "name": "Arjun Verma",
      "expiry": "26 Oct 2027",
      "enabled": true,
      "ignition": true,
      "gps": true,
      "locked": true,
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

    var filteredVehicles = vehicles.where((v) {
      final matchesSearch = searchQuery.isEmpty ||
          v['model'].toString().toLowerCase().contains(searchQuery) ||
          v['imei'].toString().toLowerCase().contains(searchQuery) ||
          v['vin'].toString().toLowerCase().contains(searchQuery) ||
          v['name'].toString().toLowerCase().contains(searchQuery) ||
          v['expiry'].toString().toLowerCase().contains(searchQuery);

      final matchesTab = selectedTab == "All" ||
          (selectedTab == "Running" && v['motion'] == "RUNNING") ||
          (selectedTab == "Stopped" && v['motion'] == "STOPPED");

      return matchesSearch && matchesTab;
    }).toList()
      ..sort((a, b) => _safeParseDateTime(b['last_activity']).compareTo(_safeParseDateTime(a['last_activity'])));

    return AppLayout(
      title: "ADMIN",
      subtitle: "Vehicles Management",
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
                  hintText: "Search model, IMEI, VIN, user...",
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
              children: ["All", "Running", "Stopped"].map((tab) {
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
                  "Showing ${filteredVehicles.length} of ${vehicles.length} vehicles",
                  style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface.withOpacity(0.87)),
                ),
                /*
                GestureDetector(
                  onTap: () => context.push("/admin/vehicles/add"),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: hp * 1.5, vertical: spacing),
                    decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: colorScheme.primary, width: 1)),
                    child: Text(
                      "Add Vehicle",
                      style: GoogleFonts.inter(fontSize: bodyFs - 3, fontWeight: FontWeight.w600, color: colorScheme.primary),
                    ),
                  ),
                ),
                */
              ],
            ),
            SizedBox(height: spacing * 1.5),

            // VEHICLE CARDS
            ...filteredVehicles.asMap().entries.map((entry) {
              final index = entry.key;
              final vehicle = entry.value;

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
                      onTap: () => context.push("/admin/vehicles/details/${vehicle['id']}"),
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
                                  child: Icon(CupertinoIcons.car_detailed, size: AdaptiveUtils.getFsAvatarFontSize(width), color: colorScheme.primary),
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
                                              Text(vehicle["model"], style: GoogleFonts.inter(fontSize: bodyFs + 2, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                              SizedBox(width: spacing),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: spacing + 4, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: vehicle["motion"] == "RUNNING" ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: Text(
                                                  vehicle["motion"],
                                                  style: GoogleFonts.inter(
                                                    fontSize: smallFs,
                                                    fontWeight: FontWeight.w600,
                                                    color: vehicle["motion"] == "RUNNING" ? Colors.green : Colors.red,
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
                                          Icon(CupertinoIcons.device_laptop, size: iconSize, color: colorScheme.primary.withOpacity(0.6)),
                                          SizedBox(width: spacing),
                                          Text("IMEI: ${vehicle["imei"]}", style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                        ],
                                      ),
                                      SizedBox(height: spacing / 2),
                                      Row(
                                        children: [
                                          Icon(CupertinoIcons.tag, size: iconSize, color: colorScheme.primary.withOpacity(0.6)),
                                          SizedBox(width: spacing),
                                          Text("VIN: ${vehicle["vin"]}", style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                        ],
                                      ),
                                      SizedBox(height: spacing / 2),
                                      Row(
                                        children: [
                                          Icon(vehicle["motion"] == "RUNNING" ? CupertinoIcons.arrow_right : CupertinoIcons.stop, size: iconSize, color: vehicle["motion"] == "RUNNING" ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.7)),
                                          SizedBox(width: spacing),
                                          Text(
                                            "${vehicle["motion"]} • ${vehicle["duration"]} • ${vehicle["speed"]}",
                                            style: GoogleFonts.inter(
                                              fontSize: bodyFs - 1,
                                              color: vehicle["motion"] == "RUNNING" ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.7),
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
                            Row(
  mainAxisSize: MainAxisSize.min,
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    // PRIMARY USER (DO NOT use Expanded here)
    Flexible(
      fit: FlexFit.loose,
      child: _userInfo(
        vehicle["initials"],
        vehicle["name"],
        width,
        colorScheme,
        spacing,
        bodyFs,
        smallFs,
      ),
    ),

    SizedBox(width: spacing * 3),

    // ICONS
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          vehicle["ignition"]
              ? CupertinoIcons.bolt_fill
              : CupertinoIcons.bolt_slash_fill,
          size: iconSize,
          color: vehicle["ignition"] ? Theme.of(context).colorScheme.primary : Colors.red,
        ),
        SizedBox(width: spacing * 2),
        Icon(
          vehicle["gps"]
              ? CupertinoIcons.location_fill
              : CupertinoIcons.location_slash_fill,
          size: iconSize,
          color: vehicle["gps"] ? Theme.of(context).colorScheme.primary : Colors.red,
        ),
        SizedBox(width: spacing * 2),
        Icon(
          vehicle["locked"]
              ? CupertinoIcons.lock_fill
              : CupertinoIcons.lock_open_fill,
          size: iconSize,
          color: vehicle["locked"] ? Theme.of(context).colorScheme.primary : Colors.red,
        ),
      ],
    ),
  ],
),
                            SizedBox(height: spacing * 2),
                            // LAST SEEN + SWITCH
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Last Activity: ${vehicle["last_activity"]}",
                                  style: GoogleFonts.inter(fontSize: smallFs + 1, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.87)),
                                ),
                                Transform.scale(
                                  scale: 0.85,
                                  child: Switch(
                                    value: vehicle["enabled"],
                                    activeColor: colorScheme.onPrimary,
                                    activeTrackColor: colorScheme.primary,
                                    inactiveThumbColor: colorScheme.onSurfaceVariant,
                                    inactiveTrackColor: colorScheme.surfaceVariant,
                                    onChanged: (v) => setState(() {
                                      vehicle["enabled"] = v;
                                    }),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing),
                            Divider(color: colorScheme.outline.withOpacity(0.3)),
                            SizedBox(height: spacing),
                            Text(
                              "Expiry: ${vehicle["expiry"]}",
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

  Widget _userInfo(String initials, String name, double width, ColorScheme scheme, double spacing, double bodyFs, double smallFs) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: scheme.primary,
          child: Text(initials, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: scheme.onPrimary)),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Driver", style: GoogleFonts.inter(fontSize: smallFs - 1, color: scheme.onSurface.withOpacity(0.6))),
              Text(name, style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.bold, color: scheme.onSurface)),
            ],
          ),
        ),
      ],
    );
  }
}