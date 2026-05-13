import 'package:open_vts/features/user/presentation/controllers/user_driver_list_controller.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/shared/widgets/custom_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/user/di/user_driver_providers.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class AssignDriverScreen extends ConsumerStatefulWidget {
  final String? current;

  const AssignDriverScreen({super.key, this.current});

  @override
  ConsumerState<AssignDriverScreen> createState() => _AssignDriverScreenState();
}

class _AssignDriverScreenState extends ConsumerState<AssignDriverScreen> {
  final TextEditingController _searchController = TextEditingController();

  String? selected;

  @override
  void initState() {
    super.initState();
    selected = widget.current;
    _searchController.addListener(() => updateLocalUiState(this, () {}));
    Future.microtask(_loadDrivers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  Future<void> _loadDrivers() async {
    await ref.read(userDriverListControllerProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(w) * 1.5;
    final driverState = ref.watch(userDriverListControllerProvider);
    final loading = driverState.isLoading;
    final drivers = driverState.items;
    final query = _searchController.text.trim().toLowerCase();

    final filteredDrivers = drivers.where((d) {
      if (query.isEmpty) return true;
      return d.fullName.toLowerCase().contains(query) ||
          d.fullPhone.toLowerCase().contains(query) ||
          d.email.toLowerCase().contains(query);
    }).toList();

    final double iconContainerSize = AdaptiveUtils.getAvatarSize(w);
    final double innerIconSize = AdaptiveUtils.getIconSize(w) * 0.9;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(hp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Assign to Driver',
                    style: AppFonts.inter(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _searchController,
                hintText: 'Search drivers',
                prefixIcon: Icons.search,
                fontSize: AdaptiveUtils.getTitleFontSize(w),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: loading
                    ? ListView.separated(
                        itemCount: 5,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, __) => const AppShimmer(
                          width: double.infinity,
                          height: 92,
                          radius: 20,
                        ),
                      )
                    : filteredDrivers.isEmpty
                    ? Container(
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: cs.onSurface.withOpacity(0.05),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No drivers found',
                              style: AppFonts.inter(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Add a driver first, then return to assign it to this route.',
                              style: AppFonts.inter(
                                color: cs.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredDrivers.length,
                        itemBuilder: (context, index) {
                          final driver = filteredDrivers[index];
                          final isSelected = selected == driver.fullName;
                          final statusColor = driver.isActive
                              ? Colors.green
                              : Colors.red;
                          final location = driver.addressLocation.trim().isEmpty
                              ? driver.email
                              : driver.addressLocation;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: cs.onSurface.withOpacity(0.05),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () =>
                                    updateLocalUiState(this, () => selected = driver.fullName),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: hp * 0.8,
                                    vertical: hp * 0.4,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        height: iconContainerSize,
                                        width: iconContainerSize,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: cs.primary.withOpacity(0.1),
                                        ),
                                        child: Center(
                                          child: Text(
                                            driver.initials,
                                            style: TextStyle(
                                              fontSize: innerIconSize,
                                              fontWeight: FontWeight.bold,
                                              color: cs.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              driver.fullName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppFonts.inter(
                                                fontSize:
                                                    AdaptiveUtils.getSubtitleFontSize(
                                                      w,
                                                    ) -
                                                    2,
                                                fontWeight: FontWeight.bold,
                                                color: cs.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${driver.fullPhone} • $location',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppFonts.inter(
                                                fontSize:
                                                    AdaptiveUtils.getTitleFontSize(
                                                      w,
                                                    ) -
                                                    2,
                                                color: cs.onSurface.withOpacity(
                                                  0.55,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              driver.statusLabel,
                                              style: AppFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: statusColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle
                                            : CupertinoIcons.chevron_forward,
                                        size:
                                            AdaptiveUtils.getIconSize(w) * 0.8,
                                        color: isSelected
                                            ? cs.primary
                                            : cs.onSurface.withOpacity(0.4),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selected != null
                          ? () => Navigator.pop(context, selected)
                          : null,
                      child: const Text('Assign'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

