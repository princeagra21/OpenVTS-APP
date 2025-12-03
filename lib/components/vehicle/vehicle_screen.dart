import 'package:fleet_stack/components/small_box/small_box.dart';
import 'package:fleet_stack/layout/app_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/adaptive_utils.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  String selectedTab = "All";
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> vehicles = [
    {
      "id": 0,
      "plate": "MH12 CD 9042",
      "type": "Car",
      "imei": "352094560123789",
      "motion": "Stop",
      "speed": "0km/h",
      "engine": "OFF",
      "primary_user_initials": "RS",
      "primary_user_name": "Riya Sharma",
      "primary_user_username": "@riya.s",
      "added_by_initials": "VS",
      "added_by_name": "Vinod Singh",
      "added_by_username": "@vinod.s",
      "created_date": "17 Oct 2025",
      "created_time": "03:25",
      "license_pri": "2026-07-15",
      "license_sec": "2026-10-15",
      "last_activity_date": "12 Jan 2025",
      "last_activity_time": "09:35",
      "status": "Active",
      "active": true,
    },
    {
      "id": 1,
      "plate": "UP14 JK 5501",
      "type": "Truck",
      "imei": "861234598765432",
      "motion": "Stop",
      "speed": "0km/h",
      "engine": "OFF",
      "primary_user_initials": "PM",
      "primary_user_name": "Pooja Mishra",
      "primary_user_username": "@pooja.m",
      "added_by_initials": "SG",
      "added_by_name": "Seema Gupta",
      "added_by_username": "@seema.g",
      "created_date": "17 Oct 2025",
      "created_time": "03:39",
      "license_pri": "2026-11-01",
      "license_sec": "2027-02-01",
      "last_activity_date": "22 Dec 2024",
      "last_activity_time": "07:25",
      "status": "Inactive",
      "active": false,
    },
    {
      "id": 2,
      "plate": "WB20 QR 3310",
      "type": "Car",
      "imei": "352099887654321",
      "motion": "Stop",
      "speed": "0km/h",
      "engine": "OFF",
      "primary_user_initials": "AS",
      "primary_user_name": "Aditi Sen",
      "primary_user_username": "@aditi.s",
      "added_by_initials": "VS",
      "added_by_name": "Vinod Singh",
      "added_by_username": "@vinod.s",
      "created_date": "17 Oct 2025",
      "created_time": "03:34",
      "license_pri": "2026-12-20",
      "license_sec": "2027-03-20",
      "last_activity_date": "05 Oct 2024",
      "last_activity_time": "14:15",
      "status": "Active",
      "active": true,
    },
    {
      "id": 3,
      "plate": "PB08 WX 7780",
      "type": "Tractor",
      "imei": "352198760054321",
      "motion": "Stop",
      "speed": "0km/h",
      "engine": "OFF",
      "primary_user_initials": "GS",
      "primary_user_name": "Gurpreet Singh",
      "primary_user_username": "@gurpreet.s",
      "added_by_initials": "VS",
      "added_by_name": "Vinod Singh",
      "added_by_username": "@vinod.s",
      "created_date": "17 Oct 2025",
      "created_time": "03:12",
      "license_pri": "2026-03-19",
      "license_sec": "2026-06-19",
      "last_activity_date": "19 Aug 2024",
      "last_activity_time": "05:35",
      "status": "Active",
      "active": true,
    },
    {
      "id": 4,
      "plate": "CG04 BB 5566",
      "type": "Bus",
      "imei": "861234507894561",
      "motion": "Stop",
      "speed": "0km/h",
      "engine": "OFF",
      "primary_user_initials": "TR",
      "primary_user_name": "Tanvi Rao",
      "primary_user_username": "@tanvi.r",
      "added_by_initials": "VS",
      "added_by_name": "Vinod Singh",
      "added_by_username": "@vinod.s",
      "created_date": "17 Oct 2025",
      "created_time": "03:14",
      "license_pri": "2026-09-09",
      "license_sec": "2026-12-09",
      "last_activity_date": "02 Aug 2025",
      "last_activity_time": "10:30",
      "status": "Active",
      "active": true,
    },
    {
      "id": 5,
      "plate": "KL07 EE 1230",
      "type": "Car",
      "imei": "352067890123456",
      "motion": "Stop",
      "speed": "0km/h",
      "engine": "OFF",
      "primary_user_initials": "VM",
      "primary_user_name": "Vivek Menon",
      "primary_user_username": "@vivek.m",
      "added_by_initials": "VS",
      "added_by_name": "Vinod Singh",
      "added_by_username": "@vinod.s",
      "created_date": "17 Oct 2025",
      "created_time": "03:16",
      "license_pri": "2026-01-12",
      "license_sec": "2026-04-12",
      "last_activity_date": "21 Sept 2025",
      "last_activity_time": "06:41",
      "status": "Active",
      "active": true,
    },
    {
      "id": 6,
      "plate": "UK07 HH 9909",
      "type": "SUV",
      "imei": "863450987601234",
      "motion": "Stop",
      "speed": "0km/h",
      "engine": "OFF",
      "primary_user_initials": "DJ",
      "primary_user_name": "Divya Joshi",
      "primary_user_username": "@divya.j",
      "added_by_initials": "VS",
      "added_by_name": "Vinod Singh",
      "added_by_username": "@vinod.s",
      "created_date": "17 Oct 2025",
      "created_time": "03:37",
      "license_pri": "2026-12-31",
      "license_sec": "2027-03-31",
      "last_activity_date": "15 Oct 2025",
      "last_activity_time": "04:39",
      "status": "Active",
      "active": true,
    },
    {
      "id": 7,
      "plate": "AS01 DD 9900",
      "type": "Truck",
      "imei": "863401298765432",
      "motion": "Running",
      "speed": "80km/h",
      "engine": "ON",
      "primary_user_initials": "IA",
      "primary_user_name": "Imran Ali",
      "primary_user_username": "@imran.a",
      "added_by_initials": "SG",
      "added_by_name": "Seema Gupta",
      "added_by_username": "@seema.g",
      "created_date": "17 Oct 2025",
      "created_time": "03:30",
      "license_pri": "2027-06-25",
      "license_sec": "2027-09-25",
      "last_activity_date": "03 Sept 2025",
      "last_activity_time": "05:00",
      "status": "Active",
      "active": true,
    },
    {
      "id": 8,
      "plate": "TN09 NP 6611",
      "type": "Van",
      "imei": "861205479012346",
      "motion": "Running",
      "speed": "71km/h",
      "engine": "ON",
      "primary_user_initials": "HK",
      "primary_user_name": "Harish K",
      "primary_user_username": "@harish.k",
      "added_by_initials": "SG",
      "added_by_name": "Seema Gupta",
      "added_by_username": "@seema.g",
      "created_date": "17 Oct 2025",
      "created_time": "03:20",
      "license_pri": "2027-03-05",
      "license_sec": "2027-06-05",
      "last_activity_date": "11 Apr 2025",
      "last_activity_time": "07:30",
      "status": "Active",
      "active": true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // --- ADAPTIVE VALUES ---
    final padding = AdaptiveUtils.getHorizontalPadding(screenWidth); // 8–16
    final spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth); // 6–10
    final titleFs = AdaptiveUtils.getTitleFontSize(screenWidth); // 13–15
    final bodyFs = titleFs - 1; // general text
    final smallFs = titleFs - 3;
    final iconSize = titleFs + 2;
    final cardPadding = padding + 4; // slightly bigger for cards

    final String searchQuery = _searchController.text.toLowerCase();

    final List<Map<String, dynamic>> filteredVehicles = vehicles.where((vehicle) {
      final bool matchesSearch = searchQuery.isEmpty ||
          (vehicle['plate'] as String).toLowerCase().contains(searchQuery) ||
          (vehicle['type'] as String).toLowerCase().contains(searchQuery) ||
          (vehicle['imei'] as String).toLowerCase().contains(searchQuery) ||
          (vehicle['primary_user_name'] as String).toLowerCase().contains(searchQuery) ||
          (vehicle['primary_user_username'] as String).toLowerCase().contains(searchQuery) ||
          (vehicle['added_by_name'] as String).toLowerCase().contains(searchQuery) ||
          (vehicle['added_by_username'] as String).toLowerCase().contains(searchQuery);

      bool matchesTab = true;
      if (selectedTab == 'Active') {
        matchesTab = vehicle['active'] as bool;
      } else if (selectedTab == 'Inactive') {
        matchesTab = !(vehicle['active'] as bool);
      }

      return matchesSearch && matchesTab;
    }).toList();

    return AppLayout(
      title: "SUPER ADMIN",
      subtitle: "Vehicles",
      actionIcons: const [
        CupertinoIcons.add,
      ],
      leftAvatarText: 'SA',
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
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(fontSize: bodyFs),
                decoration: InputDecoration(
                  hintText: "Search plate, type, user, IMEI...",
                  hintStyle: GoogleFonts.inter(
                    color: Colors.black.withOpacity(0.5),
                    fontSize: bodyFs,
                  ),
                  prefixIcon: Icon(CupertinoIcons.search, size: iconSize),
                  border: InputBorder.none,
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
              children: ["All", "Active", "Inactive"].map((tab) {
                return SmallTab(
                  label: tab,
                  selected: selectedTab == tab,
                  onTap: () => setState(() => selectedTab = tab),
                );
              }).toList(),
            ),
            SizedBox(height: padding),
            // --------------------------------------------
            // TOP ROW: showing count + export
            // --------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Showing ${filteredVehicles.length} of ${vehicles.length} vehicles",
                  style: GoogleFonts.inter(
                    fontSize: bodyFs,
                    color: Colors.black.withOpacity(0.87),
                  ),
                ),
                // EXPORT BUTTON (labeled as "Add Vehicle" in original, but comment suggests export; assuming add for now)
               GestureDetector(
  onTap: () {
    context.push("/vehicles/add");
  },
  child: Container(
    padding: EdgeInsets.symmetric(
      horizontal: padding * 1.5,
      vertical: spacing,
    ),
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.black, width: 1),
    ),
    child: Text(
      "Add Vehicle",
      style: GoogleFonts.inter(
        fontSize: bodyFs - 3,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
),

              ],
            ),
            SizedBox(height: spacing),
            // --------------------------------------------
            // VEHICLE LIST
            // --------------------------------------------
            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredVehicles.length,
              itemBuilder: (context, index) {
                final vehicle = filteredVehicles[index];
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
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(25),
                    child: InkWell(
                      onTap: () {
                        context.push("/vehicles/details/${vehicle['id']}");
                      },
                      borderRadius: BorderRadius.circular(25),
                      child: Padding(
                        padding: EdgeInsets.all(cardPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: AdaptiveUtils.getAvatarSize(screenWidth),
                                  height: AdaptiveUtils.getAvatarSize(screenWidth),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      CupertinoIcons.car_detailed, // you can change this icon
                                      size: AdaptiveUtils.getFsAvatarFontSize(screenWidth),
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                SizedBox(width: spacing * 2),
                                // RIGHT SIDE
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // PLATE + STATUS + TYPE
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                vehicle["plate"],
                                                style: GoogleFonts.inter(
                                                  fontSize: bodyFs,
                                                  fontWeight: FontWeight.bold,
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
                                                  color: vehicle["status"] == "Active"
                                                      ? Colors.green.withOpacity(0.2)
                                                      : Colors.orange.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: Text(
                                                  vehicle["status"],
                                                  style: GoogleFonts.inter(
                                                    fontSize: smallFs,
                                                    fontWeight: FontWeight.w600,
                                                    color: vehicle["status"] == "Active"
                                                        ? Colors.green
                                                        : Colors.orange,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          // TYPE
                                          Text(
                                            vehicle["type"],
                                            style: GoogleFonts.inter(
                                              fontSize: smallFs + 1,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: spacing),
                                      // IMEI
                                      Row(
                                        children: [
                                          Icon(CupertinoIcons.device_phone_portrait, size: iconSize),
                                          SizedBox(width: spacing),
                                          Text(
                                            vehicle["imei"],
                                            style: GoogleFonts.inter(
                                              fontSize: bodyFs,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: spacing / 2),
                                      // ALIGN under the text (NOT icon)
                                      Padding(
                                        padding: EdgeInsets.only(left: iconSize + spacing),
                                        child: Text(
                                          "${vehicle["motion"]} • ${vehicle["speed"]} • ${vehicle["engine"]}",
                                          style: GoogleFonts.inter(
                                            fontSize: bodyFs,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing * 2),
                            // PRIMARY USER + ADDED BY
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: padding,
                                      vertical: spacing - 2,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.black.withOpacity(0.7)),
                                    ),
                                    child: Text(
                                      "${vehicle["primary_user_initials"]} ${vehicle["primary_user_name"]} ${vehicle["primary_user_username"]}",
                                      style: GoogleFonts.inter(fontSize: smallFs),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                SizedBox(width: spacing * 2),
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: padding,
                                      vertical: spacing - 2,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.black.withOpacity(0.7)),
                                    ),
                                    child: Text(
                                      "${vehicle["added_by_initials"]} ${vehicle["added_by_name"]} ${vehicle["added_by_username"]}",
                                      style: GoogleFonts.inter(
                                        fontSize: smallFs,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing * 2),
                            // LAST ACTIVITY + SWITCH
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Last activity: ${vehicle["last_activity_date"]} ${vehicle["last_activity_time"]}",
                                  style: GoogleFonts.inter(
                                    fontSize: smallFs + 1,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Transform.scale(
                                  scale: 0.75,
                                  child: Switch(
                                    value: vehicle["active"],
                                    onChanged: (v) {
                                      setState(() {
                                        vehicle["active"] = v;
                                        vehicle["status"] = v ? "Active" : "Inactive";
                                      });
                                    },
                                    activeColor: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing),
                            Row(
                              children: [
                                Icon(CupertinoIcons.doc_checkmark, size: iconSize),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: Text(
                                    "Pri ${vehicle["license_pri"]} ✓ • Sec ${vehicle["license_sec"]} ✓",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(fontSize: bodyFs),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing),
                            Divider(),
                            SizedBox(height: spacing),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Created: ${vehicle["created_date"]} ${vehicle["created_time"]}",
                                    style: GoogleFonts.inter(
                                      fontSize: smallFs,
                                      color: Colors.black.withOpacity(0.6),
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