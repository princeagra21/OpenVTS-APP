import 'package:fleet_stack/components/vehicle/widget/send_command.dart';
import 'package:fleet_stack/components/vehicle/widget/vehicle_config_tab.dart';
import 'package:fleet_stack/components/vehicle/widget/vehicle_details_tab.dart';
import 'package:fleet_stack/components/vehicle/widget/vehicle_documents_tab.dart';
import 'package:fleet_stack/components/vehicle/widget/vehicle_logs_tab.dart';
import 'package:fleet_stack/components/vehicle/widget/vehicle_users_tab.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_stack/layout/app_layout.dart';
import 'package:fleet_stack/components/admin/navigate.dart';

// Import your tab widgets here
// import 'vehicle_details_tab.dart';
// import 'vehicle_users_tab.dart';
// import 'send_commands_tab.dart';
// import 'vehicle_logs_tab.dart';
// import 'vehicle_maps_tab.dart';
// import 'vehicle_documents_tab.dart';
// import 'vehicle_config_tab.dart';

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
    
   return AppLayout(
  title: "VEHICLE",
  subtitle: "DL01 AB 1287",
  showLeftAvatar: false,
  leftAvatarText: "🚗",
  child: SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // VEHICLE HEADER (Fix height)
        Padding(
          padding: const EdgeInsets.only(bottom: 20), // <- consistent spacing
          child: _buildVehicleHeader(),
        ),

        // NAVIGATE TABS (Stable position)
        NavigateBox(
          selectedTab: selectedTab,
          tabs: tabs,
          onTabSelected: (newTab) {
            setState(() => selectedTab = newTab);
          },
        ),
        const SizedBox(height: 24),

        // TAB SCREEN CONTENT
        _buildTabContent(),

        const SizedBox(height: 24),
      ],
    ),
  ),
);
  }

  Widget _buildVehicleHeader() {
     final double screenWidth = MediaQuery.of(context).size.width;
     final double descriptionFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) - 3;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top line: Vehicle No + Status + Device Type + Vehicle Type
          Center(
            child: Row(
              children: [
                Text(
                  "DL01 AB 1287",
                  style: GoogleFonts.inter(fontSize: descriptionFontSize, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "RUNNING",
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "GT06",
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Text(
                  "Truck",
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Bottom line: Last seen • Speed • Ignition • Location
          
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (selectedTab) {
      case "Vehicle Details":
        return Column(
          children: [
            const VehicleDetailsTab(),
          ],
        );
      case "Vehicle Users":
        return const VehicleUsersTab();
      case "Send Commands":
        return const SendCommandsTab();
      case "Logs":
        return const VehicleLogsTab();
      case "Maps":
      //  return const VehicleMapsTab();
      case "Documents":
        return const VehicleDocumentsTab();
      case "Vehicle Config":
        return const VehicleConfigTab();
      default:
        return const SizedBox.shrink();
    }
  }
}
