// screens/vehicles/vehicle_screen.dart
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/user/layout/app_layout.dart';
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

  final List<Map<String, dynamic>> vehicles = [
    {
      "vehicle_no": "TN01AB1234",
      "imei": "861586030987654",
      "gmt": "GMT+05:30",
      "last_data": "2025-11-12 10:30:00",
      "expiry": "2025-12-31",
      "status": "active",
    },
    {
      "vehicle_no": "KA05CD5678",
      "imei": "861586030987655",
      "gmt": "GMT+05:30",
      "last_data": "2025-11-11 15:45:00",
      "expiry": "2025-10-15",
      "status": "expired",
    },
    {
      "vehicle_no": "MH12EF9012",
      "imei": "861586030987656",
      "gmt": "GMT+05:30",
      "last_data": "2025-11-10 08:20:00",
      "expiry": "2026-01-20",
      "status": "suspended",
    },
    {
      "vehicle_no": "DL01PC4567",
      "imei": "861586030987657",
      "gmt": "GMT+05:30",
      "last_data": "2026-01-02 14:22:10",
      "expiry": "2026-06-30",
      "status": "active",
    },
    {
      "vehicle_no": "GJ15XY8901",
      "imei": "861586030987658",
      "gmt": "GMT+05:30",
      "last_data": "2025-12-30 09:15:45",
      "expiry": "2025-11-30",
      "status": "expired",
    },
    {
      "vehicle_no": "RJ14UV2345",
      "imei": "861586030987659",
      "gmt": "GMT+05:30",
      "last_data": "2025-12-28 18:40:00",
      "expiry": "2026-03-15",
      "status": "suspended",
    },
    {
      "vehicle_no": "HR26DE6789",
      "imei": "861586030987660",
      "gmt": "GMT+05:30",
      "last_data": "2026-01-03 08:10:30",
      "expiry": "2026-12-31",
      "status": "active",
    },
    {
      "vehicle_no": "UP32FG4567",
      "imei": "861586030987661",
      "gmt": "GMT+05:30",
      "last_data": "2025-10-20 12:55:00",
      "expiry": "2025-09-01",
      "status": "expired",
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
          v['vehicle_no'].toString().toLowerCase().contains(searchQuery) ||
          v['imei'].toString().toLowerCase().contains(searchQuery);

      final matchesTab = selectedTab == "All" ||
          v['status'].toString().toLowerCase() == selectedTab.toLowerCase();

      return matchesSearch && matchesTab;
    }).toList()
      ..sort((a, b) {
        try {
          final DateTime da = DateFormat('yyyy-MM-dd HH:mm:ss').parse(a['last_data']);
          final DateTime db = DateFormat('yyyy-MM-dd HH:mm:ss').parse(b['last_data']);
          return db.compareTo(da);
        } catch (e) {
          return 0;
        }
      });

    Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'active':
          return Colors.green;
        case 'expired':
          return Colors.red;
        case 'suspended':
          return Colors.orange;
        default:
          return colorScheme.onSurface.withOpacity(0.6);
      }
    }
      return AppLayout(
        title: "USER",
        subtitle: "Vehicles",
        actionIcons: const [CupertinoIcons.add],
        onActionTaps: [() => context.push("/user/vehicles/add")],
        showLeftAvatar: false,
        leftAvatarText: 'VH',
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
                    hintText: "Search vehicle no, IMEI...",
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
                children: ["All", "Active", "Expired", "Suspended"].map((tab) {
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
                "Showing ${filteredVehicles.length} of ${vehicles.length} vehicles",
                style: GoogleFonts.inter(
                  fontSize: bodyFs,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
              SizedBox(height: spacing * 1.5),

              // VEHICLE CARDS
              ...filteredVehicles.asMap().entries.map((entry) {
                final index = entry.key;
                final vehicle = entry.value;
                final status = vehicle['status'] as String;
                final statusColor = getStatusColor(status);

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
                              // CAR ICON
                              Container(
                                width: AdaptiveUtils.getAvatarSize(width),
                                height: AdaptiveUtils.getAvatarSize(width),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.primary.withOpacity(0.1),
                                ),
                                child: Icon(
                                  CupertinoIcons.car_detailed,
                                  size: AdaptiveUtils.getIconSize(width),
                                  color: colorScheme.primary,
                                ),
                              ),
                              SizedBox(width: spacing * 1.5),
                              // MAIN INFO
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vehicle['vehicle_no'],
                                      style: GoogleFonts.inter(
                                        fontSize: bodyFs + 2,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    SizedBox(height: spacing / 2),
                                    Text(
                                      "IMEI: ${vehicle['imei']}",
                                      style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface),
                                    ),
                                    SizedBox(height: spacing / 2),
                                    Text(
                                      "GMT: ${vehicle['gmt']}",
                                      style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface),
                                    ),
                                    SizedBox(height: spacing / 2),
                                    Text(
                                      "Last Data: ${vehicle['last_data']}",
                                      style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface),
                                    ),
                                    SizedBox(height: spacing / 2),
                                    Text(
                                      "Expiry: ${vehicle['expiry']}",
                                      style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface),
                                    ),
                                  ],
                                ),
                              ),
                              // STATUS + ACTION
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: spacing + 4, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      status[0].toUpperCase() + status.substring(1),
                                      style: GoogleFonts.inter(
                                        fontSize: smallFs + 1,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: spacing * 2),
                                  if (status == "expired")
                                    OutlinedButton(
  onPressed: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment flow TBD')),
    );
  },
  style: OutlinedButton.styleFrom(
    minimumSize: const Size(100, 36),
    side: const BorderSide(color: Colors.red),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10), // 👈 more circular
    ),
  ),
  child: Text(
    "Pay Now",
    style: GoogleFonts.inter(
      fontWeight: FontWeight.w600,
      color: Colors.red,
    ),
  ),
)

                                  else
                                    Text(
                                      "-",
                                      style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface.withOpacity(0.4)),
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
