part of 'sub_user_details_screen.dart';

extension _SubUserDetailsVehiclesTab on _SubUserDetailsScreenState {
  Widget _buildVehiclesTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final spacing = AdaptiveUtils.getLeftSectionSpacing(w);
    final cardPadding = AdaptiveUtils.getHorizontalPadding(w) + 4;
    final scale = (w / 420).clamp(0.9, 1.0);
    final fsMain = 14 * scale;
    final fsSecondary = 12 * scale;
    final fsMeta = 11 * scale;
    final iconSize = 18.0;

    final formState = ref.watch(userSubUserDetailControllerProvider(widget.userId));
    final vehicles = formState.vehicles;
    final allVehicles = formState.allVehicles;
    final assigning = formState.isAssigning;

    if (formState.isLoadingVehicles) {
      return const AppShimmer(width: double.infinity, height: 180, radius: 12);
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Assigned Vehicles',
                style: AppFonts.roboto(
                  fontSize: fsMain + 2,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              ElevatedButton(
                onPressed: assigning
                    ? null
                    : () async {
                        await _loadAllVehicles();
                        if (!context.mounted) return;
                        _showAssignVehiclesSheet(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Assign Vehicles',
                  style: AppFonts.roboto(
                    fontSize: fsSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing / 2),
          Text(
            vehicles.isEmpty
                ? 'No vehicles assigned to this sub-user.'
                : 'Vehicle list for this sub-user',
            style: AppFonts.roboto(
              fontSize: fsSecondary,
              color: cs.onSurface.withOpacity(0.7),
            ),
          ),
          SizedBox(height: spacing),
          if (vehicles.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(cardPadding),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.surfaceContainerHighest),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No vehicles assigned',
                    style: AppFonts.roboto(
                      fontSize: fsMain + 2,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  SizedBox(height: spacing / 2),
                  Text(
                    'Assign vehicles to this sub-user to see them here.',
                    style: AppFonts.roboto(
                      fontSize: fsSecondary,
                      color: cs.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
          else
            ...vehicles.map((vehicle) {
              final name = _safe(vehicle['name']?.toString());
              final plate = _safe(vehicle['plateNumber']?.toString());
              final vin = _safe(vehicle['vin']?.toString());
              final imei = _safe(
                vehicle['imei']?.toString() ??
                    (vehicle['device'] is Map
                        ? (vehicle['device']['imei']?.toString() ?? '')
                        : ''),
              );
              final sim = _safe(
                vehicle['simNumber']?.toString() ??
                    (vehicle['device'] is Map
                        ? (vehicle['device']['sim']?.toString() ?? '')
                        : ''),
              );

              return Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: spacing),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40 * (fsMain / 14),
                            height: 40 * (fsMain / 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? cs.surfaceContainerHighest
                                  : Colors.grey.shade50,
                              border: Border.all(
                                color: cs.outline.withOpacity(0.3),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.directions_car_outlined,
                              size: 18 * (fsMain / 14),
                              color: cs.primary,
                            ),
                          ),
                          SizedBox(width: spacing * 1.5),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: AppFonts.roboto(
                                          fontSize: fsMain,
                                          height: 20 / 14,
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: assigning
                                          ? null
                                          : () => _unassignVehicleFromSubUser(
                                              vehicle,
                                              context,
                                            ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: cs.error,
                                      ),
                                      child: Text(
                                        'Unassign',
                                        style: AppFonts.roboto(
                                          fontSize: fsSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: spacing * 0.4),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: spacing + 4,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? cs.surfaceContainerHighest
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    plate,
                                    style: AppFonts.roboto(
                                      fontSize: fsMeta,
                                      height: 14 / 11,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(height: spacing * 0.4),
                                Text(
                                  vin,
                                  style: AppFonts.roboto(
                                    fontSize: fsSecondary,
                                    height: 16 / 12,
                                    fontWeight: FontWeight.w500,
                                    color: cs.onSurface.withOpacity(0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: spacing * 1.2,
                                vertical: spacing - 2,
                              ),
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: cs.onSurface.withOpacity(0.1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.memory_outlined,
                                        size: iconSize,
                                        color: cs.onSurface.withOpacity(0.7),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'IMEI',
                                        style: AppFonts.roboto(
                                          fontSize: fsMeta,
                                          height: 14 / 11,
                                          fontWeight: FontWeight.w500,
                                          color: cs.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: spacing),
                                  Text(
                                    imei,
                                    style: AppFonts.roboto(
                                      fontSize: fsMain,
                                      height: 20 / 14,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: spacing / 2),
                                  Text(
                                    ' ',
                                    style: AppFonts.roboto(
                                      fontSize: fsSecondary,
                                      height: 16 / 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.transparent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: spacing),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: spacing * 1.2,
                                vertical: spacing - 2,
                              ),
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: cs.onSurface.withOpacity(0.1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.memory_outlined,
                                        size: iconSize,
                                        color: cs.onSurface.withOpacity(0.7),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'SIM',
                                        style: AppFonts.roboto(
                                          fontSize: fsMeta,
                                          height: 14 / 11,
                                          fontWeight: FontWeight.w500,
                                          color: cs.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: spacing + 2),
                                  Text(
                                    sim,
                                    style: AppFonts.roboto(
                                      fontSize: fsMain,
                                      height: 20 / 14,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: spacing / 2),
                                  Text(
                                    ' ',
                                    style: AppFonts.roboto(
                                      fontSize: fsSecondary,
                                      height: 16 / 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.transparent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showAssignVehiclesSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final formState = ref.read(userSubUserDetailControllerProvider(widget.userId));
    final vehicles = formState.vehicles;
    final allVehicles = formState.allVehicles;
    final assignedIds = vehicles
        .map((v) => v['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final available = allVehicles
        .where((v) => !assignedIds.contains(v['id']?.toString() ?? ''))
        .toList();

    final selected = <String>{};

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.7,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Assign Vehicles',
                              style: AppFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              height: 32,
                              width: 32,
                              decoration: BoxDecoration(
                                color: cs.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: available.isEmpty
                            ? Center(
                                child: Text(
                                  'No available vehicles to assign.',
                                  style: AppFonts.roboto(
                                    fontSize: 12,
                                    color: cs.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: available.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 4),
                                itemBuilder: (context, index) {
                                  final v = available[index];
                                  final id = v['id']?.toString() ?? '';
                                  final name = _safe(v['name']?.toString());
                                  final plate = _safe(
                                    v['plateNumber']?.toString(),
                                  );
                                  final checked = selected.contains(id);
                                  return CheckboxListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 4.0,
                                    ),
                                    title: Text(
                                      '$name • $plate',
                                      style: AppFonts.roboto(fontSize: 14),
                                    ),
                                    value: checked,
                                    onChanged: (bool? checked) {
                                      setSheetState(() {
                                        if (checked == true) {
                                          selected.add(id);
                                        } else {
                                          selected.remove(id);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: selected.isEmpty
                                    ? null
                                    : () async {
                                        Navigator.pop(ctx);
                                        await _assignSelectedVehicles(
                                          selected.toList(),
                                        );
                                      },
                                child: const Text('Done'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
