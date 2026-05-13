import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:open_vts/features/admin/di/admin_map_providers.dart';
import 'package:open_vts/features/admin/presentation/components/appbars/admin_home_appbar.dart';
import 'package:open_vts/features/admin/presentation/layout/app_layout.dart';
import 'package:open_vts/features/map/presentation/open_vts_map/open_vts_map_screen.dart';
import 'package:open_vts/features/map/presentation/providers/open_vts_map_repository_provider.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppLayout(
      title: 'MAP',
      subtitle: 'Vehicle Locations',
      actionIcons: const [],
      leftAvatarText: 'MP',
      showAppBar: false,
      showBottomBar: false,
      horizontalPadding: 0.0,
      child: ProviderScope(
        overrides: [
          openVtsMapRepositoryProvider.overrideWithValue(
            ref.read(adminOpenVtsMapAdapterProvider),
          ),
        ],
        child: OpenVtsMapScreen(
          appBarBuilder: (context) {
            return const AdminHomeAppBar(
              title: 'Map',
              leadingIcon: Symbols.map,
              borderRadius: 0,
            );
          },
        ),
      ),
    );
  }
}
