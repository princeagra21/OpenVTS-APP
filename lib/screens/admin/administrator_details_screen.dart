import 'package:fleet_stack/components/admin/info_grids.dart';
import 'package:fleet_stack/components/admin/navigate%20.dart';
import 'package:fleet_stack/components/admin/profile_box.dart';
import 'package:fleet_stack/layout/app_layout.dart';
import 'package:flutter/material.dart';

class AdministratorDetailsScreen extends StatelessWidget {
  final String id;

  const AdministratorDetailsScreen({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: "ADMINISTRATOR",
      subtitle: "Muhammad Sani",
      actionIcons: const [Icons.more_horiz],
      showLeftAvatar: false,
      leftAvatarText: 'AM',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileBox(),
            const SizedBox(height: 24),
            NavigateBox(),
            const SizedBox(height: 24),
            AdminInfoBoxes(),
            const SizedBox(height: 24),
            
          ],
        ),
      ),
    );
  }
}