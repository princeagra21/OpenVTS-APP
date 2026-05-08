import 'package:open_vts/core/repositories/user_vehicles_repository.dart';
import 'package:open_vts/modules/user/components/appbars/user_home_appbar.dart';
import 'package:open_vts/modules/user/layout/app_layout.dart';
import 'package:open_vts/shared/map/open_vts_map_repository.dart';
import 'package:open_vts/shared/map/open_vts_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'MAP',
      subtitle: 'Vehicle Locations',
      actionIcons: const [],
      leftAvatarText: 'MP',
      showAppBar: false,
      horizontalPadding: 0.0,
      child: OpenVtsMapScreen(
        repositoryBuilder: (apiClient) {
          return UserMapTelemetryAdapter(
            repository: UserVehiclesRepository(api: apiClient),
          );
        },
        appBarBuilder: (context) {
          return const UserHomeAppBar(
            title: 'Map',
            leadingIcon: Symbols.map,
            borderRadius: 0,
          );
        },
      ),
    );
  }
}
