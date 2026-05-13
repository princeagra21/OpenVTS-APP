import 'package:flutter/material.dart';
import 'package:open_vts/features/vehicles/domain/config/vehicle_role_config.dart';

class VehicleFilterBar extends StatelessWidget {
  const VehicleFilterBar({
    super.key,
    required this.searchController,
    required this.selectedTab,
    required this.config,
    required this.onSearchChanged,
    required this.onTabSelected,
  });

  final TextEditingController searchController;
  final String selectedTab;
  final VehicleRoleConfig config;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
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
          if (config.availableTabs.length > 1)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: config.availableTabs.length,
                itemBuilder: (context, index) {
                  final tab = config.availableTabs[index];
                  final isSelected = selectedTab == tab;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(tab),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) onTabSelected(tab);
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
