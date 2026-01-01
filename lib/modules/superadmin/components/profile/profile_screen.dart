// components/profile/profile_screen.dart
import 'package:fleet_stack/modules/superadmin/components/profile/widget/profile_company_box.dart';
import 'package:fleet_stack/modules/superadmin/components/profile/widget/profile_delete_box.dart';
import 'package:fleet_stack/modules/superadmin/components/profile/widget/profile_info_boxes.dart';
import 'package:fleet_stack/modules/superadmin/components/profile/widget/profile_recent_activity_box.dart';
import 'package:fleet_stack/modules/superadmin/components/profile/widget/profile_setting_box.dart';
import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) -2 ;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "Profile",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 8,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          children:  [
            ProfileSettingBox(),
            SizedBox(height: 24),
            ProfileInfoBoxes(),
            SizedBox(height: 24,),
            ProfileCompanyBox(),
            SizedBox(height: 24,),
            ProfileRecentActivityBox(),
            SizedBox(height: 24,),
            ProfileDeleteBox(onDelete: () { },),
            SizedBox(height: 24,),
          ],
        ),
      ),
    );
  }
}
