import 'package:flutter/material.dart';
import 'package:open_vts/core/network/api_client_provider.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/features/admin_tools/server_status/server_status_controller.dart';
import 'package:open_vts/features/admin_tools/server_status/server_status_repository.dart';
import 'package:open_vts/features/admin_tools/server_status/widgets/server_health_summary.dart';
import 'package:open_vts/modules/superadmin/layout/app_layout.dart';

class ServerStatusScreen extends StatefulWidget {
  const ServerStatusScreen({super.key});

  @override
  State<ServerStatusScreen> createState() => _ServerStatusScreenState();
}

class _ServerStatusScreenState extends State<ServerStatusScreen> {
  late final ServerStatusController _controller;

  @override
  void initState() {
    super.initState();
    final api = ApiClientProvider.shared();
    final repo = ServerStatusRepository(api: api);
    _controller = ServerStatusController(repository: repo)..loadStatus();
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
      subtitle: "Server Status",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ServerHealthSummary(controller: _controller),
            const SizedBox(height: 24),
            // Add more sections here
          ],
        ),
      ),
    );
  }
}