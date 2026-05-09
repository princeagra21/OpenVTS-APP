import 'package:flutter/material.dart';
import 'package:open_vts/features/vehicles/vehicle_controller.dart';
import 'package:open_vts/features/vehicles/vehicle_role_config.dart';

/// Vehicle filter bar with tabs and search
class VehicleFilterBar extends StatelessWidget {
  const VehicleFilterBar({
    super.key,
    required this.controller,
    required this.config,
  });

  final VehicleController controller;
  final VehicleRoleConfig config;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search vehicles...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          // Tabs
          if (config.availableTabs.length > 1)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: config.availableTabs.length,
                itemBuilder: (context, index) {
                  final tab = config.availableTabs[index];
                  final isSelected = controller.state.selectedTab == tab;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(tab),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          controller.setSelectedTab(tab);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}