import 'package:flutter/material.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/features/localization/localization_role_config.dart';
import 'package:open_vts/features/localization/localization_screen.dart';
import 'package:open_vts/modules/admin/layout/app_layout.dart';

class AdminLocalizationScreen extends StatelessWidget {
  const AdminLocalizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    return AppLayout(
      title: 'Open VTS',
      subtitle: LocalizationRoleConfigs.admin.subtitle,
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocalizationScreen(config: LocalizationRoleConfigs.admin),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class LocalizationSettingsScreen extends AdminLocalizationScreen {
  const LocalizationSettingsScreen({super.key});
}
