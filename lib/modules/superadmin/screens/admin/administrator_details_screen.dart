
import 'package:fleet_stack/modules/superadmin/components/admin/credit_history/credit_history_tab.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/documents_tab/documents_tab.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/navigate.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/profile_box.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/profile_tab/profile_tab.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/role_tab.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/setting_tab/setting.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/vehicles_tab/vehicles_tab.dart';
import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart' show AppLayout;
import 'package:flutter/material.dart';

class AdministratorDetailsScreen extends StatefulWidget {  // Made stateful to manage tab state
  final String id;

  const AdministratorDetailsScreen({
    super.key,
    required this.id,
  });

  @override
  State<AdministratorDetailsScreen> createState() => _AdministratorDetailsScreenState();
}

class _AdministratorDetailsScreenState extends State<AdministratorDetailsScreen> {
  String selectedTab = "Profile";

  final List<String> tabs = [
    "Profile",
    "Credit History",
    "Documents",
    "Vehicles",
    "Setting",
    "Roles"
  ];

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: "ADMINISTRATOR",
      subtitle: "Muhammad Sani",
      showLeftAvatar: false,
      leftAvatarText: 'AM',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ProfileBox(),  // Assuming this is always visible as a header
            const SizedBox(height: 24),
            NavigateBox(
              selectedTab: selectedTab,
              tabs: tabs,
              onTabSelected: (newTab) {
                setState(() {
                  selectedTab = newTab;
                });
              },
            ),
            const SizedBox(height: 4),
            _buildTabContent(),  // Dynamic content based on selected tab
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

Widget _buildTabContent() {
  switch (selectedTab) {
    case "Profile":
      return Column(
        children: const [
          SizedBox(height: 24),
          ProfileTab(),
        ],
      );
    case "Credit History":
      return Column(
        children: const [
          SizedBox(height: 24),
          CreditHistoryTab(),
          SizedBox(height: 24),
        ],
      );
    case "Documents":
      return Column(
        children: const [
          SizedBox(height: 24),
          DocumentsTab(),
          SizedBox(height: 24),
        ],
      );

   case "Vehicles":
  return
   Column(
     children: [
       SizedBox(height: 24),
        VehiclesTab(),
        SizedBox(height: 24),
     ],
   );


    case "Setting":
      return Column(
        children: const [
          SizedBox(height: 24),
          AdminSettingsTab(),
          SizedBox(height: 24),
        ],
      );

    case "Roles":
      return Column(
        children: const [
          SizedBox(height: 24),
          RolesTab(),
          SizedBox(height: 24),
        ],
      );

    default:
      return const SizedBox.shrink();
  }
}


}

// Temporary placeholder widget - replace with your actual content widgets
class PlaceholderContent extends StatelessWidget {
  final String label;

  const PlaceholderContent({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      color: Colors.grey[200],
      child: Center(
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

