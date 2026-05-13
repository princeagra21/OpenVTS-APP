import 'package:flutter/material.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/features/localization/domain/config/localization_role_config.dart';
import 'package:open_vts/features/localization/presentation/screens/localization_screen.dart';
import 'package:open_vts/features/superadmin/presentation/layout/app_layout.dart';

class SuperadminLocalizationScreen extends StatelessWidget {
  const SuperadminLocalizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    return AppLayout(
      title: 'Open VTS',
      subtitle: LocalizationRoleConfigs.superadmin.subtitle,
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocalizationScreen(config: LocalizationRoleConfigs.superadmin),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class LocalizationSettingsScreen extends SuperadminLocalizationScreen {
  const LocalizationSettingsScreen({super.key});
}
