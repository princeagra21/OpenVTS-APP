import 'package:fleet_stack/components/small_box/small_box.dart';
import 'package:fleet_stack/layout/app_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/adaptive_utils.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  String selectedTab = "All";
  final TextEditingController _searchController = TextEditingController();

  // Safe date parser
  DateTime _safeParseDate(String dateStr) {
    try {
      return DateFormat('dd MMM yyyy').parse(dateStr);
    } catch (e) {
      try {
        return DateTime.parse(dateStr); // fallback for yyyy-MM-dd
      } catch (_) {
        return DateTime.now();
      }
    }
  }

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
      "last_activity_date": "21 Sep 2025",
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
      "last_activity_date": "03 Sep 2025",
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
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color getAvatarColor(String initials) {
    final hash = initials.codeUnits.fold(0, (p, c) => p + c);
    return Colors.primaries[hash % Colors.primaries.length].shade600;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth);
    final titleFs = AdaptiveUtils.getTitleFontSize(screenWidth);
    final bodyFs = titleFs - 1;
    final smallFs = titleFs - 3;
    final iconSize = titleFs + 2;
    final cardPadding = padding + 4;

    final primaryColor = Colors.blue.shade700;
    final accentColor = Colors.green.shade600;
    final now = DateTime.now();

    final searchQuery = _searchController.text.toLowerCase();

    var filteredVehicles = vehicles.where((v) {
      final matchesSearch = searchQuery.isEmpty ||
          v['plate'].toString().toLowerCase().contains(searchQuery) ||
          v['type'].toString().toLowerCase().contains(searchQuery) ||
          v['imei'].toString().toLowerCase().contains(searchQuery) ||
          (v['primary_user_name'] as String).toLowerCase().contains(searchQuery) ||
          (v['added_by_name'] as String).toLowerCase().contains(searchQuery);

      final matchesTab = selectedTab == "All" ||
          (selectedTab == "Active" && v['active'] == true) ||
          (selectedTab == "Inactive" && v['active'] == false);

      return matchesSearch && matchesTab;
    }).toList()
      ..sort((a, b) => _safeParseDate(b['last_activity_date'])
          .compareTo(_safeParseDate(a['last_activity_date'])));

    return AppLayout(
      title: "SUPER ADMIN",
      subtitle: "Vehicles",
      actionIcons: const [CupertinoIcons.add],
      leftAvatarText: 'SA',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search
            Container(
              height: padding * 3.5,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(fontSize: bodyFs),
                decoration: InputDecoration(
                  hintText: "Search plate, type, user, IMEI...",
                  hintStyle: GoogleFonts.inter(color: Colors.black54, fontSize: bodyFs),
                  prefixIcon: Icon(CupertinoIcons.search, size: iconSize),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
                ),
              ),
            ),
            SizedBox(height: padding),

            // Tabs
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

            // Count + Add Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Showing ${filteredVehicles.length} of ${vehicles.length} vehicles",
                  style: GoogleFonts.inter(fontSize: bodyFs, color: Colors.black87),
                ),
                GestureDetector(
                  onTap: () => context.push("/vehicles/add"),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: padding * 1.5, vertical: spacing),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                    child: Text("Add Vehicle", style: GoogleFonts.inter(fontSize: bodyFs - 3, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 1.5),

            // Vehicle Cards
            ...filteredVehicles.asMap().entries.map((entry) {
              final index = entry.key;
              final vehicle = entry.value;

              final priDate = _safeParseDate(vehicle["license_pri"]);
              final secDate = _safeParseDate(vehicle["license_sec"]);
              final isPriExpiring = priDate.difference(now).inDays < 30;
              final isSecExpiring = secDate.difference(now).inDays < 30;

              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + index * 50),
                curve: Curves.easeOut,
                margin: EdgeInsets.only(bottom: padding),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: LinearGradient(colors: [Colors.white, Colors.grey.shade50], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: () => context.push("/vehicles/details/${vehicle['id']}"),
                      child: Padding(
                        padding: EdgeInsets.all(cardPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top: Icon + Plate + Status + Type
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: AdaptiveUtils.getAvatarSize(screenWidth),
                                  height: AdaptiveUtils.getAvatarSize(screenWidth),
                                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black12)),
                                  child: Icon(CupertinoIcons.car_detailed, size: AdaptiveUtils.getFsAvatarFontSize(screenWidth), color: Colors.black),
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
                                              Text(vehicle["plate"], style: GoogleFonts.inter(fontSize: bodyFs + 2, fontWeight: FontWeight.bold)),
                                              SizedBox(width: spacing),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: spacing + 4, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: vehicle["active"] ? Colors.green.shade100 : Colors.orange.shade100,
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: Text(vehicle["status"], style: GoogleFonts.inter(fontSize: smallFs, fontWeight: FontWeight.w600, color: vehicle["active"] ? Colors.green.shade800 : Colors.orange.shade800)),
                                              ),
                                            ],
                                          ),
                                          Text(vehicle["type"], style: GoogleFonts.inter(fontSize: smallFs + 2, fontWeight: FontWeight.w600, color: Colors.black87)),
                                        ],
                                      ),
                                      SizedBox(height: spacing / 2),
                                      Row(
                                        children: [
                                          Icon(CupertinoIcons.device_phone_portrait, size: iconSize, color: Colors.black54),
                                          SizedBox(width: spacing),
                                          Text(vehicle["imei"], style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                      SizedBox(height: spacing / 2),
                                      Padding(
                                        padding: EdgeInsets.only(left: iconSize + spacing),
                                        child: Text(
                                          "${vehicle["motion"]} • ${vehicle["speed"]} • ${vehicle["engine"]}",
                                          style: GoogleFonts.inter(fontSize: bodyFs - 1, color: vehicle["engine"] == "ON" ? accentColor : Colors.black.withOpacity(0.7)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: spacing * 2),

                            // PRIMARY USER & ADDED BY — NOW IN SAME ROW
                            Row(
                              children: [
                                // Primary User
                                Expanded(
                                  child: Row(
                                    children: [
                                      CircleAvatar(radius: 18, backgroundColor: getAvatarColor(vehicle["primary_user_initials"]), child: Text(vehicle["primary_user_initials"], style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white))),
                                      SizedBox(width: spacing),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("Primary User", style: GoogleFonts.inter(fontSize: smallFs - 1, color: Colors.black54, fontWeight: FontWeight.w600)),
                                            Text(vehicle["primary_user_name"], style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.bold)),
                                            Text(vehicle["primary_user_username"], style: GoogleFonts.inter(fontSize: smallFs, color: Colors.black54)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Added By
                                Expanded(
                                  child: Row(
                                    children: [
                                      CircleAvatar(radius: 18, backgroundColor: getAvatarColor(vehicle["added_by_initials"]), child: Text(vehicle["added_by_initials"], style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white))),
                                      SizedBox(width: spacing),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("Added By", style: GoogleFonts.inter(fontSize: smallFs - 1, color: Colors.black54, fontWeight: FontWeight.w600)),
                                            Text(vehicle["added_by_name"], style: GoogleFonts.inter(fontSize: bodyFs, fontWeight: FontWeight.bold)),
                                            Text(vehicle["added_by_username"], style: GoogleFonts.inter(fontSize: smallFs, color: Colors.black54)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: spacing * 2),

                            // Last Seen + Switch
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Last Seen: ${vehicle["last_activity_date"]} ${vehicle["last_activity_time"]}", style: GoogleFonts.inter(fontSize: smallFs + 1, fontWeight: FontWeight.w600, color: Colors.black87)),
                                Transform.scale(
                                  scale: 0.85,
                                  child: Switch(
                                    value: vehicle["active"],
                                    activeColor: Colors.black,
                                    onChanged: (v) => setState(() {
                                      vehicle["active"] = v;
                                      vehicle["status"] = v ? "Active" : "Inactive";
                                    }),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: spacing),

                            // License Info
                            Row(
                              children: [
                                Icon(CupertinoIcons.doc_checkmark_fill, size: iconSize, color: primaryColor),
                                SizedBox(width: spacing),
                                Expanded(child: Text("Primary: ${vehicle["license_pri"]} ${isPriExpiring ? 'Expiring soon' : 'Valid'}", style: GoogleFonts.inter(fontSize: bodyFs - 1, color: isPriExpiring ? Colors.red.shade700 : Colors.black87))),
                                Expanded(child: Text("Secondary: ${vehicle["license_sec"]} ${isSecExpiring ? 'Expiring soon' : 'Valid'}", textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: bodyFs - 1, color: isSecExpiring ? Colors.red.shade700 : Colors.black87))),
                              ],
                            ),

                            SizedBox(height: spacing),
                            Divider(color: Colors.grey.shade300, thickness: 0.5),
                            SizedBox(height: spacing),
                            Text("Created: ${vehicle["created_date"]} ${vehicle["created_time"]}", style: GoogleFonts.inter(fontSize: smallFs, color: Colors.black54)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),

            SizedBox(height: padding * 3),
          ],
        ),
      ),
    );
  }
}