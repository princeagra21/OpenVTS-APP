import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_driver_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_drivers_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  // Endpoint truth table (FleetStack-API-Reference.md + Postman):
  // - GET /admin/drivers (query: search, status, page, limit)
  // - GET /admin/drivers/:id (details, not wired in this list slice)
  // - PATCH /admin/drivers/:id
  //   Postman body key: isactive
  //   Compatibility payload used: { isactive: bool, isActive: bool }

  String selectedTab = 'All';
  final TextEditingController _searchController = TextEditingController();

  List<AdminDriverListItem>? _drivers;
  bool _loading = false;
  bool _errorShown = false;

  CancelToken? _loadToken;
  final Map<String, bool> _updating = <String, bool>{};
  final Map<String, CancelToken> _toggleTokens = <String, CancelToken>{};

  Timer? _searchDebounce;

  ApiClient? _apiClient;
  AdminDriversRepository? _repo;

  AdminDriversRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminDriversRepository(api: _apiClient!);
    return _repo!;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadDrivers();
  }

  @override
  void dispose() {
    _loadToken?.cancel('Drivers screen disposed');
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();

    for (final token in _toggleTokens.values) {
      token.cancel('Drivers screen disposed');
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
      _loadDrivers();
    });
  }

  String normalizeStatus(String? raw, {bool? isActive}) {
    return AdminDriverListItem.normalizeStatus(raw, isActive: isActive);
  }

  String? _statusQueryForTab(String tab) {
    switch (tab.toLowerCase()) {
      case 'active':
        return 'active';
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

  Future<void> _loadDrivers() async {
    _loadToken?.cancel('Reload drivers');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final result = await _repoOrCreate().getDrivers(
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
            _drivers = items;
            _loading = false;
            _errorShown = false;
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() {
            _drivers = const <AdminDriverListItem>[];
            _loading = false;
          });

          if (_isCancelled(err)) return;

          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load drivers.'
              : "Couldn't load drivers.";
          _showLoadErrorOnce(message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _drivers = const <AdminDriverListItem>[];
        _loading = false;
      });
      _showLoadErrorOnce("Couldn't load drivers.");
    }
  }

  List<AdminDriverListItem> _applyLocalFilters(
    List<AdminDriverListItem> source,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    bool tabMatch(AdminDriverListItem item) {
      if (selectedTab == 'All') return true;
      final expected = normalizeStatus(selectedTab);
      final actual = normalizeStatus(item.rawStatus, isActive: item.isActive);
      return expected == actual;
    }

    bool queryMatch(AdminDriverListItem item) {
      if (query.isEmpty) return true;

      final fields = [
        item.fullName,
        item.username,
        item.fullPhone,
        item.email,
        item.addressLocation,
        item.statusLabel,
        item.lastActivityAt,
        item.expiryDate,
      ];

      return fields.any((v) => v.toLowerCase().contains(query));
    }

    return source.where((d) => tabMatch(d) && queryMatch(d)).toList()..sort(
      (a, b) => _safeParseDateTime(
        b.lastActivityAt,
      ).compareTo(_safeParseDateTime(a.lastActivityAt)),
    );
  }

  DateTime _safeParseDateTime(String dateStr) {
    final text = dateStr.trim();
    if (text.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);

    final parsed = DateTime.tryParse(text);
    if (parsed != null) return parsed;

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _safe(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return '—';
    if (trimmed.toLowerCase() == 'null') return '—';
    return trimmed;
  }

  Future<void> _makePhoneCall(String rawPhone) async {
    final phone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.trim().isEmpty) return;

    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open dialer for $rawPhone')),
    );
  }

  Future<void> _toggleDriverActive(
    AdminDriverListItem item,
    bool nextValue,
  ) async {
    final driverId = item.id.trim();
    if (driverId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Driver ID is missing.')));
      return;
    }

    if (_updating[driverId] == true) return;

    final previousValue = item.isActive;
    _setDriverActiveOptimistic(driverId, nextValue);

    if (mounted) {
      setState(() {
        _updating[driverId] = true;
      });
    }

    _toggleTokens[driverId]?.cancel('Replace driver status request');
    final token = CancelToken();
    _toggleTokens[driverId] = token;

    try {
      final result = await _repoOrCreate().updateDriverStatus(
        driverId,
        nextValue,
        cancelToken: token,
      );
      if (!mounted) return;

      result.when(
        success: (_) {
          if (!mounted) return;
          setState(() {
            _updating.remove(driverId);
            _toggleTokens.remove(driverId);
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() {
            _setDriverActiveOptimistic(driverId, previousValue);
            _updating.remove(driverId);
            _toggleTokens.remove(driverId);
          });

          if (_isCancelled(err)) return;

          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to update driver status.'
              : "Couldn't update driver status.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _setDriverActiveOptimistic(driverId, previousValue);
        _updating.remove(driverId);
        _toggleTokens.remove(driverId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't update driver status.")),
      );
    }
  }

  void _setDriverActiveOptimistic(String driverId, bool isActive) {
    final list = _drivers;
    if (list == null) return;

    final updated = list.map((driver) {
      if (driver.id != driverId) return driver;

      final raw = Map<String, dynamic>.from(driver.raw);
      raw['isactive'] = isActive;
      raw['isActive'] = isActive;
      raw['active'] = isActive;
      raw['enabled'] = isActive;
      raw['status'] = isActive ? 'Active' : 'Inactive';
      return AdminDriverListItem.fromRaw(raw);
    }).toList();

    _drivers = updated;
  }

  Color _statusBgColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('active')) return Colors.green.withOpacity(0.15);
    if (s.contains('inactive') || s.contains('disable')) {
      return Colors.red.withOpacity(0.15);
    }
    return Colors.orange.withOpacity(0.15);
  }

  Color _statusTextColor(String status, ColorScheme colorScheme) {
    final s = status.toLowerCase();
    if (s.contains('active')) return Colors.green;
    if (s.contains('inactive') || s.contains('disable')) return Colors.red;
    return colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final double titleFs = AdaptiveUtils.getTitleFontSize(width);
    final double bodyFs = titleFs - 1;
    final double smallFs = titleFs - 3;
    final double iconSize = titleFs + 2;
    final double cardPadding = hp + 4;

    final allDrivers = _drivers ?? const <AdminDriverListItem>[];
    final filteredDrivers = _applyLocalFilters(allDrivers);

    return AppLayout(
      title: 'ADMIN',
      subtitle: 'Drivers Management',
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
                  hintText: 'Search name, username, phone, email...',
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
              children: ['All', 'Active', 'Inactive'].map((tab) {
                return SmallTab(
                  label: tab,
                  selected: selectedTab == tab,
                  onTap: () {
                    if (selectedTab == tab) return;
                    setState(() => selectedTab = tab);
                    _loadDrivers();
                  },
                );
              }).toList(),
            ),
            SizedBox(height: hp),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${filteredDrivers.length} of ${allDrivers.length} drivers',
                  style: GoogleFonts.inter(
                    fontSize: bodyFs,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 1.5),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _loading
                  ? 3
                  : (filteredDrivers.isEmpty ? 1 : filteredDrivers.length),
              itemBuilder: (context, index) {
                if (_loading) {
                  return _buildShimmerCard(
                    colorScheme,
                    isDark,
                    width,
                    hp,
                    spacing,
                    bodyFs,
                    iconSize,
                    cardPadding,
                  );
                }

                if (filteredDrivers.isEmpty) {
                  return _buildEmptyStateCard(
                    colorScheme: colorScheme,
                    bodyFs: bodyFs,
                    smallFs: smallFs,
                    cardPadding: cardPadding,
                    hp: hp,
                  );
                }

                return _buildDriverCardBody(
                  driver: filteredDrivers[index],
                  colorScheme: colorScheme,
                  isDark: isDark,
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

  Widget _buildShimmerCard(
    ColorScheme colorScheme,
    bool isDark,
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
                          AppShimmer(width: 80, height: 22, radius: 11),
                        ],
                      ),
                      SizedBox(height: 8),
                      AppShimmer(width: 160, height: 14, radius: 7),
                      SizedBox(height: 8),
                      AppShimmer(width: 220, height: 14, radius: 7),
                      SizedBox(height: 8),
                      AppShimmer(width: 240, height: 14, radius: 7),
                      SizedBox(height: 8),
                      AppShimmer(width: 240, height: 14, radius: 7),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                AppShimmer(width: 180, height: 12, radius: 6),
                AppShimmer(width: 42, height: 22, radius: 11),
              ],
            ),
            SizedBox(height: spacing),
            Divider(color: colorScheme.outline.withOpacity(0.3)),
            SizedBox(height: spacing),
            const AppShimmer(width: 160, height: 12, radius: 6),
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
                  'No drivers found',
                  style: GoogleFonts.inter(
                    fontSize: bodyFs + 1,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ask superadmin to assign drivers.',
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

  Widget _buildDriverCardBody({
    required AdminDriverListItem? driver,
    required ColorScheme colorScheme,
    required bool isDark,
    required double width,
    required double spacing,
    required double bodyFs,
    required double smallFs,
    required double iconSize,
    required double cardPadding,
    required double hp,
  }) {
    final isPlaceholder = driver == null;
    final driverId = driver?.id.trim() ?? '';
    final isUpdating = _updating[driverId] == true;

    final name = _safe(driver?.fullName);
    final username = _safe(driver?.username);
    final phone = _safe(driver?.fullPhone);
    final email = _safe(driver?.email);
    final address = _safe(driver?.addressLocation);
    final status = _safe(driver?.statusLabel);
    final lastActivity = _safe(driver?.lastActivityAt);
    final expiry = _safe(driver?.expiryDate);
    final enabled = driver?.isActive ?? false;

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
                          CupertinoIcons.person,
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
                                    name,
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
                                    status.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: smallFs,
                                      fontWeight: FontWeight.w600,
                                      color: _statusTextColor(
                                        status,
                                        colorScheme,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing / 2),
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.at,
                                  size: iconSize,
                                  color: colorScheme.primary.withOpacity(0.6),
                                ),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: Text(
                                    username,
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
                                  CupertinoIcons.phone,
                                  size: iconSize,
                                  color: colorScheme.primary.withOpacity(0.87),
                                ),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: Text(
                                    phone,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: GoogleFonts.inter(
                                      fontSize: bodyFs,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Call $name',
                                  onPressed: isPlaceholder || phone == '—'
                                      ? null
                                      : () => _makePhoneCall(phone),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(
                                    minWidth: 48,
                                    minHeight: iconSize,
                                  ),
                                  icon: Icon(
                                    Icons.call,
                                    size: iconSize,
                                    color: isDark
                                        ? colorScheme.primary
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing / 2),
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.mail,
                                  size: iconSize,
                                  color: colorScheme.primary.withOpacity(0.6),
                                ),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: Text(
                                    email,
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
                                  CupertinoIcons.location,
                                  size: iconSize,
                                  color: colorScheme.primary.withOpacity(0.6),
                                ),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: Text(
                                    address,
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
                          'Last Activity: $lastActivity',
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
                                : (v) => _toggleDriverActive(driver, v),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing),
                  Divider(color: colorScheme.outline.withOpacity(0.3)),
                  SizedBox(height: spacing),
                  Text(
                    'Expiry: $expiry',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: smallFs,
                      color: colorScheme.onSurface.withOpacity(0.54),
                    ),
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
