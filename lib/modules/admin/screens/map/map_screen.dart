import 'package:open_vts/app/app_container.dart';
import 'package:open_vts/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:open_vts/modules/admin/layout/app_layout.dart';
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
      showBottomBar: false,
      horizontalPadding: 0.0,
      child: OpenVtsMapScreen(
        repository: AdminMapTelemetryAdapter(
          repository: AppContainer.instance.adminVehiclesRepository,
        ),
        appBarBuilder: (context) {
          return const AdminHomeAppBar(
            title: 'Map',
            leadingIcon: Symbols.map,
            borderRadius: 0,
          );
        },
      ),
    );
  }
}
