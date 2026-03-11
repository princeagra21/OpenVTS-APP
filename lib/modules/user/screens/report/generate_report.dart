import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/user/layout/app_layout.dart';
import 'package:flutter/material.dart';

class GenerateReportScreen extends StatelessWidget {
  const GenerateReportScreen({super.key});

  // FleetStack-API-Reference.md / Postman:
  // - no User report-generation endpoint was found for this screen
  // - keep UI honest until backend confirms report APIs

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    return AppLayout(
      title: "USER",
      subtitle: "Generate Report",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 8,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          children: [
            Text('Report API not available yet'),
            SizedBox(height: 24),
            Text(
              'Backend to confirm report generation endpoints for User module',
            ),
          ],
        ),
      ),
    );
  }
}
