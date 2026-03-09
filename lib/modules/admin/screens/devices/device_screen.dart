import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_device_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_devices_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  // Endpoint truth table (FleetStack-API-Reference.md + Postman):
  // - GET /admin/devices (query: search, status, page, limit)
  // - PATCH /admin/devices/:id (status toggle, key: isActive)
  // - POST /admin/devices (add flow handled in AddDeviceScreen)

  String selectedTab = 'All';
  final TextEditingController _searchController = TextEditingController();

  List<AdminDeviceListItem>? _devices;
  bool _loading = false;
  bool _errorShown = false;

  CancelToken? _loadToken;
  final Map<String, bool> _updating = <String, bool>{};
  final Map<String, CancelToken> _toggleTokens = <String, CancelToken>{};

  Timer? _searchDebounce;

  ApiClient? _apiClient;
  AdminDevicesRepository? _repo;

  AdminDevicesRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminDevicesRepository(api: _apiClient!);
    return _repo!;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadDevices();
  }

  @override
  void dispose() {
    _loadToken?.cancel('Devices screen disposed');
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();

    for (final token in _toggleTokens.values) {
      token.cancel('Devices screen disposed');
    }
    _toggleTokens.clear();

    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _loadDevices();
    });
  }

  String normalizeStatus(String? raw, {bool? isActive}) {
    return AdminDeviceListItem.normalizeStatus(raw, isActive: isActive);
  }

  String? _statusQueryForTab(String tab) {
    switch (tab.toLowerCase()) {
      case 'active':
        return 'active';
      case 'maintenance':
        return 'maintenance';
      case 'inactive':
        return 'inactive';
      default:
        return null;
    }
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  void _showLoadErrorOnce(String message) {
    if (_errorShown || !mounted) return;
    _errorShown = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadDevices() async {
    _loadToken?.cancel('Reload devices');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final result = await _repoOrCreate().getDevices(
        search: _searchController.text.trim(),
        status: _statusQueryForTab(selectedTab),
        page: 1,
        limit: 100,
        cancelToken: token,
      );
      if (!mounted) return;

      result.when(
        success: (items) {
          if (!mounted) return;
          setState(() {
            _devices = items;
            _loading = false;
            _errorShown = false;
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() {
            _devices = const <AdminDeviceListItem>[];
            _loading = false;
          });

          if (_isCancelled(err)) return;

          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load devices.'
              : "Couldn't load devices.";
          _showLoadErrorOnce(message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _devices = const <AdminDeviceListItem>[];
        _loading = false;
      });
      _showLoadErrorOnce("Couldn't load devices.");
    }
  }

  List<AdminDeviceListItem> _applyLocalFilters(
    List<AdminDeviceListItem> source,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    bool tabMatch(AdminDeviceListItem item) {
      if (selectedTab == 'All') return true;
      final expected = normalizeStatus(selectedTab);
      final actual = normalizeStatus(item.rawStatus, isActive: item.isActive);
      return expected == actual;
    }

    bool queryMatch(AdminDeviceListItem item) {
      if (query.isEmpty) return true;
      final fields = [
        item.imei,
        item.typeName,
        item.simNumber,
        item.provider,
        item.statusLabel,
        item.expiryDate,
      ];
      return fields.any((v) => v.toLowerCase().contains(query));
    }

    return source.where((d) => tabMatch(d) && queryMatch(d)).toList()..sort(
      (a, b) => _safeParseDateTime(
        b.expiryDate,
      ).compareTo(_safeParseDateTime(a.expiryDate)),
    );
  }

  DateTime _safeParseDateTime(String dateStr) {
    final text = dateStr.trim();
    if (text.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);

    final parsed = DateTime.tryParse(text);
    if (parsed != null) return parsed;

    final parts = text.split('/');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null) {
        return DateTime(y, m, d);
      }
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _safe(String? value, {String fallback = '—'}) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return fallback;
    if (trimmed.toLowerCase() == 'null') return fallback;
    return trimmed;
  }

  Future<void> _openAddDevice() async {
    final result = await context.push('/admin/devices/add');
    if (!mounted) return;
    if (result == true) {
      _loadDevices();
    }
  }

  Future<void> _toggleDeviceActive(
    AdminDeviceListItem item,
    bool nextValue,
  ) async {
    final deviceId = item.id.trim();
    if (deviceId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Device ID is missing.')));
      return;
    }

    if (_updating[deviceId] == true) return;

    final previousValue = item.isActive;
    _setDeviceActiveOptimistic(deviceId, nextValue);

    if (mounted) {
      setState(() {
        _updating[deviceId] = true;
      });
    }

    _toggleTokens[deviceId]?.cancel('Replace device status request');
    final token = CancelToken();
    _toggleTokens[deviceId] = token;

    try {
      final result = await _repoOrCreate().updateDeviceStatus(
        deviceId,
        nextValue,
        cancelToken: token,
      );
      if (!mounted) return;

      result.when(
        success: (_) {
          if (!mounted) return;
          setState(() {
            _updating.remove(deviceId);
            _toggleTokens.remove(deviceId);
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() {
            _setDeviceActiveOptimistic(deviceId, previousValue);
            _updating.remove(deviceId);
            _toggleTokens.remove(deviceId);
          });

          if (_isCancelled(err)) return;

          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to update device status.'
              : "Couldn't update device status.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _setDeviceActiveOptimistic(deviceId, previousValue);
        _updating.remove(deviceId);
        _toggleTokens.remove(deviceId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't update device status.")),
      );
    }
  }

  void _setDeviceActiveOptimistic(String deviceId, bool isActive) {
    final list = _devices;
    if (list == null) return;

    final updated = list.map((device) {
      if (device.id != deviceId) return device;

      final raw = Map<String, dynamic>.from(device.raw);
      raw['isActive'] = isActive;
      raw['active'] = isActive;
      raw['enabled'] = isActive;
      raw['status'] = isActive ? 'Active' : 'Inactive';
      return AdminDeviceListItem.fromRaw(raw);
    }).toList();

    _devices = updated;
  }

  Color _statusBgColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('active')) return Colors.green.withOpacity(0.15);
    if (s.contains('maintenance')) return Colors.orange.withOpacity(0.15);
    return Colors.red.withOpacity(0.15);
  }

  Color _statusTextColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('active')) return Colors.green;
    if (s.contains('maintenance')) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final double titleFs = AdaptiveUtils.getTitleFontSize(width);
    final double bodyFs = titleFs - 1;
    final double smallFs = titleFs - 3;
    final double iconSize = titleFs + 2;
    final double cardPadding = hp + 4;

    final allDevices = _devices ?? const <AdminDeviceListItem>[];
    final filteredDevices = _applyLocalFilters(allDevices);

    return AppLayout(
      title: 'ADMIN',
      subtitle: 'Devices Management',
      actionIcons: const [CupertinoIcons.add],
      showLeftAvatar: false,
      leftAvatarText: 'SA',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: hp * 3.5,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(
                  fontSize: bodyFs,
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Search IMEI, type, SIM, provider...',
                  hintStyle: GoogleFonts.inter(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: bodyFs,
                  ),
                  prefixIcon: Icon(
                    CupertinoIcons.search,
                    size: iconSize,
                    color: colorScheme.primary.withOpacity(0.7),
                  ),
                  border: InputBorder.none,
                  focusColor: colorScheme.primary,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: Colors.transparent,
                      width: 0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: hp,
                    vertical: hp,
                  ),
                ),
              ),
            ),
            SizedBox(height: hp),

            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: ['All', 'Active', 'Maintenance', 'Inactive'].map((tab) {
                return SmallTab(
                  label: tab,
                  selected: selectedTab == tab,
                  onTap: () {
                    if (selectedTab == tab) return;
                    setState(() => selectedTab = tab);
                    _loadDevices();
                  },
                );
              }).toList(),
            ),
            SizedBox(height: hp),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${filteredDevices.length} of ${allDevices.length} devices',
                  style: GoogleFonts.inter(
                    fontSize: bodyFs,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
                GestureDetector(
                  onTap: _openAddDevice,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: hp * 1.5,
                      vertical: spacing,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    child: Text(
                      'Add Device',
                      style: GoogleFonts.inter(
                        fontSize: bodyFs - 3,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 1.5),

            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _loading
                  ? 3
                  : (filteredDevices.isEmpty ? 1 : filteredDevices.length),
              itemBuilder: (context, index) {
                if (_loading) {
                  return _buildShimmerCard(
                    colorScheme,
                    width,
                    hp,
                    spacing,
                    bodyFs,
                    iconSize,
                    cardPadding,
                  );
                }

                if (filteredDevices.isEmpty) {
                  return _buildEmptyStateCard(
                    colorScheme: colorScheme,
                    bodyFs: bodyFs,
                    smallFs: smallFs,
                    cardPadding: cardPadding,
                    hp: hp,
                  );
                }

                return _buildDeviceCardBody(
                  device: filteredDevices[index],
                  colorScheme: colorScheme,
                  width: width,
                  spacing: spacing,
                  bodyFs: bodyFs,
                  smallFs: smallFs,
                  iconSize: iconSize,
                  cardPadding: cardPadding,
                  hp: hp,
                );
              },
            ),

            SizedBox(height: hp * 3),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard({
    required ColorScheme colorScheme,
    required double bodyFs,
    required double smallFs,
    required double cardPadding,
    required double hp,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: EdgeInsets.only(bottom: hp),
      child: Container(
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
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No devices found',
                  style: GoogleFonts.inter(
                    fontSize: bodyFs + 1,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a device or ask superadmin to assign one.',
                  style: GoogleFonts.inter(
                    fontSize: smallFs + 1,
                    color: colorScheme.onSurface.withOpacity(0.72),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard(
    ColorScheme colorScheme,
    double width,
    double hp,
    double spacing,
    double bodyFs,
    double iconSize,
    double cardPadding,
  ) {
    final avatarSize = AdaptiveUtils.getAvatarSize(width);

    return Container(
      margin: EdgeInsets.only(bottom: hp),
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
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer(
                  width: avatarSize,
                  height: avatarSize,
                  radius: avatarSize / 2,
                ),
                SizedBox(width: spacing * 1.5),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppShimmer(
                              width: 180,
                              height: 16,
                              radius: 8,
                            ),
                          ),
                          SizedBox(width: 8),
                          AppShimmer(width: 92, height: 22, radius: 11),
                        ],
                      ),
                      SizedBox(height: 8),
                      AppShimmer(width: 170, height: 14, radius: 7),
                      SizedBox(height: 8),
                      AppShimmer(width: 220, height: 14, radius: 7),
                      SizedBox(height: 8),
                      AppShimmer(width: 220, height: 14, radius: 7),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                AppShimmer(width: 140, height: 12, radius: 6),
                AppShimmer(width: 42, height: 22, radius: 11),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCardBody({
    required AdminDeviceListItem? device,
    required ColorScheme colorScheme,
    required double width,
    required double spacing,
    required double bodyFs,
    required double smallFs,
    required double iconSize,
    required double cardPadding,
    required double hp,
  }) {
    final isPlaceholder = device == null;
    final deviceId = device?.id.trim() ?? '';
    final isUpdating = _updating[deviceId] == true;

    final imei = _safe(device?.imei);
    final type = _safe(device?.typeName);
    final sim = _safe(device?.simNumber, fallback: 'No SIM');
    final provider = _safe(device?.provider, fallback: '-');
    final status = _safe(device?.statusLabel);
    final expiry = _safe(device?.expiryDate);
    final enabled = device?.isActive ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: EdgeInsets.only(bottom: hp),
      child: Container(
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
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: () {},
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: AdaptiveUtils.getAvatarSize(width),
                        height: AdaptiveUtils.getAvatarSize(width),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Icon(
                          CupertinoIcons.device_laptop,
                          size: AdaptiveUtils.getFsAvatarFontSize(width),
                          color: colorScheme.primary,
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
                                    imei,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: bodyFs + 2,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                SizedBox(width: spacing),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: spacing + 4,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusBgColor(status),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    status,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: smallFs,
                                      fontWeight: FontWeight.w600,
                                      color: _statusTextColor(status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing / 2),
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.device_phone_portrait,
                                  size: iconSize,
                                  color: colorScheme.primary.withOpacity(0.6),
                                ),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: Text(
                                    type,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: GoogleFonts.inter(
                                      fontSize: bodyFs,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing / 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.sim_card,
                                  size: iconSize,
                                  color: colorScheme.primary.withOpacity(0.6),
                                ),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: Text(
                                    sim,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: GoogleFonts.inter(
                                      fontSize: bodyFs,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing / 2),
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.globe,
                                  size: iconSize,
                                  color: colorScheme.primary.withOpacity(0.6),
                                ),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: Text(
                                    provider,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: GoogleFonts.inter(
                                      fontSize: bodyFs,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing * 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Expiry: $expiry',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: smallFs + 1,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withOpacity(0.87),
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: 0.85,
                        child: IgnorePointer(
                          ignoring: isPlaceholder || isUpdating,
                          child: Switch(
                            value: enabled,
                            activeColor: colorScheme.onPrimary,
                            activeTrackColor: colorScheme.primary,
                            inactiveThumbColor: colorScheme.onSurfaceVariant,
                            inactiveTrackColor: colorScheme.surfaceVariant,
                            onChanged: isPlaceholder
                                ? null
                                : (v) => _toggleDeviceActive(device, v),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
