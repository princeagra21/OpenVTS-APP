import 'package:flutter/material.dart';
import 'package:open_vts/shared/widgets/top_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/features/admin_tools/di/admin_tools_providers.dart';
import 'package:open_vts/features/admin_tools/presentation/server_status/server_status_controller.dart';
import 'package:open_vts/features/admin_tools/presentation/server_status/widgets/server_health_summary.dart';

class ServerStatusScreen extends ConsumerStatefulWidget {
  const ServerStatusScreen({super.key});

  @override
  ConsumerState<ServerStatusScreen> createState() => _ServerStatusScreenState();
}

class _ServerStatusScreenState extends ConsumerState<ServerStatusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(serverStatusControllerProvider.notifier).loadStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;
    final state = ref.watch(serverStatusControllerProvider);
    final controller = ref.read(serverStatusControllerProvider.notifier);

    return Scaffold(
      appBar: TopBar(
        title: 'Server Status',
        onClose: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ServerHealthSummary(
              state: state,
              onRefresh: controller.loadStatus,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
