import 'dart:async';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';
import 'package:open_vts/core/router/route_names.dart';

import 'package:open_vts/features/admin/domain/entities/admin_device_list_item.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/features/admin/presentation/components/admin/navigate.dart';
import 'package:open_vts/features/admin/presentation/components/appbars/admin_home_appbar.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_device_list_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String selectedTab = 'All';
  final TextEditingController _searchController = TextEditingController();
  int _pageSize = 10;

  Timer? _searchDebounce;


  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadDevices();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      updateLocalUiState(this, () {});
    }
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _loadDevices();
    });
  }

  void _showLoadErrorOnce(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadDevices() async {
    await ref.read(adminDeviceListControllerProvider.notifier).loadDevices(
          search: _searchController.text.trim(),
          status: null,
          page: 1,
          limit: 50,
        );
  }

  Future<void> _openAddInventory() async {
    final created = await context.push(AppRoutePaths.adminInventoryAdd);
    if (!mounted) return;
    if (created == true) {
      _loadDevices();
    }
  }

  Future<void> _openEditDevice(AdminDeviceListItem item) async {
    final id = item.id.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Device ID not found.')));
      return;
    }
    final updated = await context.push(AppRoutePaths.adminInventoryDevice(id), extra: item);
    if (!mounted) return;
    if (updated == true) {
      _loadDevices();
    }
  }

  Future<void> _toggleDeviceActive(AdminDeviceListItem item, bool next) async {
    final ok = await ref.read(adminDeviceListControllerProvider.notifier).updateStatus(item, next);
    if (!mounted || ok) return;
    final message = ref.read(adminDeviceListControllerProvider).errorMessage ??
        "Couldn't update device status.";
    _showLoadErrorOnce(message);
  }

  List<AdminDeviceListItem> _applyLocalFilters(List<AdminDeviceListItem> source) {
    final query = _searchController.text.trim().toLowerCase();

    bool tabMatch(AdminDeviceListItem item) {
      if (selectedTab == 'All') return true;
      final expected = selectedTab.toLowerCase();
      final actual = item.statusFilterValue.toLowerCase();
      return expected == actual;
    }

    bool queryMatch(AdminDeviceListItem item) {
      if (query.isEmpty) return true;
      final fields = [
        item.imei,
        item.simNumber,
        item.typeName,
        item.statusLabel,
        item.expiryDate,
      ];
      return fields.any((v) => v.toLowerCase().contains(query));
    }

    return source.where((d) => tabMatch(d) && queryMatch(d)).toList();
  }

  String _safe(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '—';
    return trimmed;
  }

  String _formatDateOnly(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text == '—') return '—';
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return text;
    final local = parsed.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$day/$month/$year';
  }

  int _newestFirstCompare(AdminDeviceListItem a, AdminDeviceListItem b) {
    final aDate = DateTime.tryParse(a.createdAt);
    final bDate = DateTime.tryParse(b.createdAt);
    if (aDate != null && bDate != null) return bDate.compareTo(aDate);
    if (aDate != null) return -1;
    if (bDate != null) return 1;

    final aId = int.tryParse(a.id);
    final bId = int.tryParse(b.id);
    if (aId != null && bId != null) return bId.compareTo(aId);
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth);
    final scale = (screenWidth / 390).clamp(0.9, 1.05);
    final fsSection = 18 * scale;
    final fsMain = 14 * scale;
    final fsSecondary = 12 * scale;
    final fsMeta = 11 * scale;
    final iconSize = 18.0;
    final cardPadding = padding + 4;

    final listState = ref.watch(adminDeviceListControllerProvider);
    final allDevices = listState.items;
    var filteredDevices = _applyLocalFilters(allDevices);
    filteredDevices.sort(_newestFirstCompare);
    if (filteredDevices.length > _pageSize) {
      filteredDevices = filteredDevices.take(_pageSize).toList();
    }
    final isLoading = listState.isLoading;
    final showError = listState.errorMessage != null;
    final showNoData = !isLoading && filteredDevices.isEmpty;

    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? OpenVtsColors.panelDark
          : OpenVtsColors.panelLight,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              padding,
              topPadding + AppUtils.appBarHeightCustom + 28,
              padding,
              84,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NavigateBox(
                  selectedTab: 'Device',
                  tabs: const ['Device', 'Sim'],
                  title: 'Inventory',
                  subtitle: 'Switch between device and sim inventory.',
                  onTabSelected: (tab) {
                    if (tab == 'Sim') {
                      context.go(AppRoutePaths.adminSims);
                    }
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(cardPadding),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.surfaceContainerHighest),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Inventory",
                            style: AppFonts.roboto(
                              fontSize: fsSection,
                              height: 24 / 18,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          InkWell(
                            onTap: _openAddInventory,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: padding,
                                vertical: spacing,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add,
                                    size: iconSize,
                                    color: colorScheme.onPrimary,
                                  ),
                                  SizedBox(width: spacing / 2),
                                  Text(
                                    'Add',
                                    style: AppFonts.roboto(
                                      fontSize: fsMain - 2,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: padding),
                      Container(
                        height: padding * 3.5,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colorScheme.onSurface.withOpacity(0.1),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: AppFonts.roboto(
                            fontSize: fsMain,
                            height: 20 / 14,
                            color: colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: "Search IMEI, SIM, type, status...",
                            hintStyle: AppFonts.roboto(
                              color: colorScheme.onSurface.withOpacity(0.5),
                              fontSize: fsSecondary,
                              height: 16 / 12,
                            ),
                            prefixIcon: Icon(
                              CupertinoIcons.search,
                              size: iconSize + 2,
                              color: colorScheme.onSurface,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: padding,
                              vertical: padding,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: padding),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final double gap = spacing;
                          final double cellWidth =
                              (constraints.maxWidth - gap * 2) / 3;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              SizedBox(
                                width: cellWidth,
                                child: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (selectedTab == value) return;
                                    updateLocalUiState(this, () => selectedTab = value);
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: "All",
                                      child: Text('All'),
                                    ),
                                    PopupMenuItem(
                                      value: "Active",
                                      child: Text('Active'),
                                    ),
                                    PopupMenuItem(
                                      value: "Maintenance",
                                      child: Text('Maintenance'),
                                    ),
                                    PopupMenuItem(
                                      value: "Inactive",
                                      child: Text('Inactive'),
                                    ),
                                  ],
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: padding,
                                      vertical: spacing,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.1),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.tune,
                                          size: iconSize,
                                          color: colorScheme.onSurface,
                                        ),
                                        SizedBox(width: spacing / 2),
                                        Text(
                                          "Filter",
                                          style: AppFonts.roboto(
                                            fontSize: fsMain - 3,
                                            height: 20 / 14,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: cellWidth,
                                child: PopupMenuButton<int>(
                                  onSelected: (value) {
                                    if (_pageSize == value) return;
                                    updateLocalUiState(this, () => _pageSize = value);
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 10,
                                      child: Text('10'),
                                    ),
                                    PopupMenuItem(
                                      value: 25,
                                      child: Text('25'),
                                    ),
                                    PopupMenuItem(
                                      value: 50,
                                      child: Text('50'),
                                    ),
                                  ],
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: padding,
                                      vertical: spacing,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.1),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Records",
                                              style: AppFonts.roboto(
                                                fontSize: fsMain - 3,
                                                height: 20 / 14,
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(width: spacing / 2),
                                            Icon(
                                              Icons.keyboard_arrow_down,
                                              size: iconSize,
                                              color: colorScheme.onSurface,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: cellWidth,
                                child: InkWell(
                                  onTap: _loadDevices,
                                  borderRadius: BorderRadius.circular(12),
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: padding,
                                      vertical: spacing,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.1),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.refresh,
                                          size: iconSize,
                                          color: colorScheme.onSurface,
                                        ),
                                        SizedBox(width: spacing / 2),
                                        Text(
                                          "Refresh",
                                          style: AppFonts.roboto(
                                            fontSize: fsMain - 3,
                                            height: 20 / 14,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: padding),
                      if (showNoData)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: padding),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(cardPadding),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    showError
                                        ? (listState.errorMessage ?? "Couldn't load inventory.")
                                        : "No devices found",
                                    style: AppFonts.roboto(
                                      fontSize: fsSecondary,
                                      height: 16 / 12,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (showError)
                                  TextButton(
                                    onPressed: _loadDevices,
                                    child: const Text('Retry'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      if (isLoading)
                        ...List<Widget>.generate(
                          3,
                          (index) => _buildDeviceSkeletonCard(
                            padding: padding,
                            spacing: spacing,
                            cardPadding: cardPadding,
                            screenWidth: screenWidth,
                            bodyFs: fsMain,
                            smallFs: fsMeta,
                          ),
                        ),
                      if (!showNoData && !isLoading)
                        ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredDevices.length,
                          itemBuilder: (context, index) {
                            final device = filteredDevices[index];
                            return _buildDeviceCard(
                              device,
                              colorScheme,
                              padding,
                              spacing,
                              fsMain,
                              fsSecondary,
                              fsMeta,
                              iconSize,
                              cardPadding,
                              screenWidth,
                              listState.updatingIds,
                            );
                          },
                        ),
                    ],
                  ),
                ),
                SizedBox(height: padding * 2),
              ],
            ),
          ),
          Positioned(
            left: padding,
            right: padding,
            top: 0,
            child: AdminHomeAppBar(
              title: 'Inventory',
              leadingIcon: Icons.inventory_2,
              onClose: () => context.go(AppRoutePaths.adminHome),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSkeletonCard({
    required double padding,
    required double spacing,
    required double cardPadding,
    required double screenWidth,
    required double bodyFs,
    required double smallFs,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: padding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppShimmer(
                    width: AdaptiveUtils.getAvatarSize(screenWidth),
                    height: AdaptiveUtils.getAvatarSize(screenWidth),
                    radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2,
                  ),
                  SizedBox(width: spacing * 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppShimmer(
                                width: double.infinity,
                                height: bodyFs + 8,
                                radius: 8,
                              ),
                            ),
                            SizedBox(width: spacing),
                            AppShimmer(
                              width: 70,
                              height: smallFs + 10,
                              radius: 999,
                            ),
                          ],
                        ),
                        SizedBox(height: spacing),
                        AppShimmer(
                          width: screenWidth * 0.35,
                          height: bodyFs + 8,
                          radius: 8,
                        ),
                        SizedBox(height: spacing),
                        AppShimmer(
                          width: screenWidth * 0.45,
                          height: bodyFs + 6,
                          radius: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing * 2),
              Row(
                children: [
                  Expanded(
                    child: AppShimmer(
                      width: double.infinity,
                      height: bodyFs + 18,
                      radius: 12,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: AppShimmer(
                      width: double.infinity,
                      height: bodyFs + 18,
                      radius: 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing * 2),
              AppShimmer(
                width: screenWidth * 0.4,
                height: smallFs + 10,
                radius: 8,
              ),
              SizedBox(height: spacing),
              AppShimmer(
                width: double.infinity,
                height: smallFs + 10,
                radius: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceCard(
    AdminDeviceListItem device,
    ColorScheme colorScheme,
    double padding,
    double spacing,
    double fsMain,
    double fsSecondary,
    double fsMeta,
    double iconSize,
    double cardPadding,
    double screenWidth,
    Set<String> updatingIds,
  ) {
    final imei = _safe(device.imei);
    final type = _safe(device.typeName);
    final sim = _safe(device.simNumber);
    final status = _safe(device.statusLabel);
    final created = _formatDateOnly(device.createdAt);

    return Container(
      margin: EdgeInsets.only(bottom: padding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () => _openEditDevice(device),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.surface,
                    radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2,
                    foregroundColor: colorScheme.onSurface,
                    child: Container(
                      width: AdaptiveUtils.getAvatarSize(screenWidth),
                      height: AdaptiveUtils.getAvatarSize(screenWidth),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.onSurface.withOpacity(0.12),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.memory,
                        size: AdaptiveUtils.getFsAvatarFontSize(screenWidth),
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  SizedBox(width: spacing * 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                imei,
                                style: AppFonts.roboto(
                                  fontSize: fsMain,
                                  height: 20 / 14,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Transform.scale(
                              scale: 0.85,
                              child: CupertinoSwitch(
                                activeTrackColor: colorScheme.primary,
                                value: device.isActive,
                                onChanged: updatingIds.contains(device.id)
                                    ? null
                                    : (v) => _toggleDeviceActive(device, v),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: spacing / 2),
                        Row(
                          children: [
                            Icon(
                              Icons.settings_input_component,
                              size: iconSize,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                            SizedBox(width: spacing),
                            Expanded(
                              child: Text(
                                type,
                                style: AppFonts.roboto(
                                  fontSize: fsSecondary,
                                  height: 16 / 12,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: spacing / 2),
                        Row(
                          children: [
                            Icon(
                              Icons.sim_card_outlined,
                              size: iconSize,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                            SizedBox(width: spacing),
                            Expanded(
                              child: Text(
                                sim,
                                style: AppFonts.roboto(
                                  fontSize: fsSecondary,
                                  height: 16 / 12,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing * 1.5),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? colorScheme.surfaceContainerHighest
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status,
                    style: AppFonts.roboto(
                      fontSize: fsMeta,
                      height: 14 / 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ),
              SizedBox(height: spacing),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: padding,
                  vertical: spacing - 2,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.onSurface.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: iconSize,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                        SizedBox(width: spacing),
                        Expanded(
                          child: Text(
                            "Created",
                            style: AppFonts.roboto(
                              fontSize: fsMeta,
                              height: 14 / 11,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing),
                    Text(
                      created,
                      style: AppFonts.roboto(
                        fontSize: fsMain,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}


