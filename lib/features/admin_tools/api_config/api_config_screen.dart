import 'package:flutter/material.dart';
import 'package:open_vts/core/network/api_client_provider.dart';
import 'package:open_vts/core/repositories/api_config_repository.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/features/admin_tools/api_config/api_config_controller.dart';
import 'package:open_vts/features/admin_tools/api_config/widgets/api_config_header.dart';
import 'package:open_vts/modules/superadmin/layout/app_layout.dart';

class ApiConfigScreen extends StatefulWidget {
  const ApiConfigScreen({super.key});

  @override
  State<ApiConfigScreen> createState() => _ApiConfigScreenState();
}

class _ApiConfigScreenState extends State<ApiConfigScreen> {
  late final ApiConfigController _controller;

  @override
  void initState() {
    super.initState();
    final api = ApiClientProvider.shared();
    final repo = ApiConfigRepository(api: api);
    _controller = ApiConfigController(repository: repo)..loadConfig();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    return AppLayout(
      title: "Open VTS",
      subtitle: "API Configuration",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ApiConfigHeader(controller: _controller),
            const SizedBox(height: 24),
            // Add more sections here as needed
          ],
        ),
      ),
    );
  }
}