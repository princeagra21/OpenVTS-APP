// components/admin/profile_tab.dart
import 'package:fleet_stack/modules/superadmin/components/admin/profile_tab/widget/company_box.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/profile_tab/widget/delete_account_box.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/profile_tab/widget/info_grids.dart';
import 'package:flutter/material.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AdminInfoBoxes(),
        SizedBox(height: 24),
        CompanyBox(),
        SizedBox(height: 24),
        DeleteAccountBox(),
      ],
    ); // Added CompanyBox below AdminInfoBoxes
  }
}