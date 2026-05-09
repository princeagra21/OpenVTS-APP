import 'package:open_vts/app/app_container.dart';
import 'package:open_vts/modules/superadmin/components/appbars/superadmin_home_appbar.dart';
import 'package:open_vts/modules/superadmin/layout/app_layout.dart';
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
        repository: SuperadminMapTelemetryAdapter(
          repository: AppContainer.instance.superadminRepository,
        ),
        appBarBuilder: (context) {
          return const SuperAdminHomeAppBar(
            title: 'Map',
            leadingIcon: Symbols.map,
            borderRadius: 0,
          );
        },
      ),
    );
  }
}
