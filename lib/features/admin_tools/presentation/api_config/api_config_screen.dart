import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/features/admin_tools/di/admin_tools_providers.dart';
import 'package:open_vts/features/admin_tools/presentation/api_config/api_config_controller.dart';
import 'package:open_vts/features/admin_tools/presentation/api_config/widgets/api_config_header.dart';
import 'package:open_vts/features/superadmin/presentation/layout/app_layout.dart';

class ApiConfigScreen extends ConsumerStatefulWidget {
  const ApiConfigScreen({super.key});

  @override
  ConsumerState<ApiConfigScreen> createState() => _ApiConfigScreenState();
}

class _ApiConfigScreenState extends ConsumerState<ApiConfigScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(apiConfigControllerProvider.notifier).loadConfig();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;
    final state = ref.watch(apiConfigControllerProvider);
    final controller = ref.read(apiConfigControllerProvider.notifier);

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
            ApiConfigHeader(state: state, controller: controller),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
