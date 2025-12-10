// screens/vehicle/vehicle_details_screen.dart
import 'package:fleet_stack/components/vehicle/widget/send_command.dart';
import 'package:fleet_stack/components/vehicle/widget/vehicle_config_tab.dart';
import 'package:fleet_stack/components/vehicle/widget/vehicle_details_tab.dart';
import 'package:fleet_stack/components/vehicle/widget/vehicle_documents_tab.dart';
import 'package:fleet_stack/components/vehicle/widget/vehicle_logs_tab.dart';
import 'package:fleet_stack/components/vehicle/widget/vehicle_users_tab.dart';
import 'package:fleet_stack/components/admin/navigate.dart';
import 'package:fleet_stack/layout/app_layout.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final String id;

  const VehicleDetailsScreen({super.key, required this.id});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  String selectedTab = "Vehicle Details";

  final List<String> tabs = [
    "Vehicle Details",
    "Vehicle Users",
    "Send Commands",
    "Logs",
    "Maps",
    "Documents",
    "Vehicle Config"
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double fs = AdaptiveUtils.getTitleFontSize(width);

    return AppLayout(
      title: "VEHICLE",
      subtitle: "DL01 AB 1287",
      showLeftAvatar: false,
      leftAvatarText: "Car",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // VEHICLE HEADER CARD
          Container(
            padding: EdgeInsets.all(hp),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top: Plate + Status + Model + Type
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "DL01 AB 1287",
                      style: GoogleFonts.inter(
                        fontSize: fs + 6,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "RUNNING",
                        style: GoogleFonts.inter(
                          fontSize: fs - 2,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.memory, size: fs + 2, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text("GT06", style: GoogleFonts.inter(fontSize: fs + 1, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 20),
                    Icon(Icons.local_shipping, size: fs + 2, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text("Truck", style: GoogleFonts.inter(fontSize: fs + 1, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                // Bottom info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _infoItem("Last Seen", "2 min ago", Icons.access_time, colorScheme),
                    _infoItem("Speed", "68 km/h", Icons.speed, colorScheme),
                    _infoItem("Ignition", "ON", Icons.electric_bolt, colorScheme),
                    _infoItem("Location", "Mumbai, MH", Icons.location_on, colorScheme),
                  ],
                ),
              ],
            ),
          ),
      
          const SizedBox(height: 28),
      
          // TABS
          NavigateBox(
            selectedTab: selectedTab,
            tabs: tabs,
            onTabSelected: (tab) => setState(() => selectedTab = tab),
          ),
          const SizedBox(height: 24),
      
          // TAB CONTENT
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildTabContent(key: ValueKey(selectedTab)),
          ),
      
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value, IconData icon, ColorScheme scheme) {
    final double width = MediaQuery.of(context).size.width;
    final double fs = AdaptiveUtils.getTitleFontSize(width);

    return Column(
      children: [
        Icon(icon, size: fs + 4, color: scheme.primary),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.inter(fontSize: fs - 4, color: scheme.onSurface.withOpacity(0.6))),
        Text(value, style: GoogleFonts.inter(fontSize: fs - 1, fontWeight: FontWeight.bold, color: scheme.onSurface)),
      ],
    );
  }

 Widget _buildTabContent({Key? key}) {
  Widget content;

  switch (selectedTab) {
    case "Vehicle Details":
      content = VehicleDetailsTab();
      break;
    case "Vehicle Users":
      content = const VehicleUsersTab();  // This one needs scrolling
      break;
    case "Send Commands":
      content = SendCommandsTab();
      break;
    case "Logs":
      content = VehicleLogsTab();
      break;
    case "Maps":
      content = const Center(child: Text("Maps Tab - Coming Soon", style: TextStyle(fontSize: 18)));
      break;
    case "Documents":
      content = VehicleDocumentsTab();
      break;
    case "Vehicle Config":
      content = VehicleConfigTab();
      break;
    default:
      content = const SizedBox();
  }

  // If the content is a ListView (or any primary scrollable), wrap in Expanded
  // Otherwise, let it be as is (for fixed-height content)
  if (selectedTab == "Vehicle Users" || selectedTab == "Logs") {
    return Expanded(
      key: key,
      child: content,
    );
  }

  return Container(
    key: key,
    child: content,
  );
}
}