import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_driver_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_drivers_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
  int _pageSize = 10;

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
        status: null,
        page: 1,
        limit: 50,
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

  String _initials(String source) {
    final clean = source.trim();
    if (clean.isEmpty || clean == '—') return '--';
    final parts = clean
        .split(RegExp(r'\\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '--';
    return parts.take(2).map((part) => part[0]).join().toUpperCase();
  }

  String _formatDateOnly(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return '—';
    final dt = DateTime.tryParse(value);
    if (dt == null) return value;
    final local = dt.toLocal();
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = local.day.toString().padLeft(2, '0');
    final month = months[local.month - 1];
    final year = local.year.toString();
    return '$day $month $year';
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

    final allDrivers = _drivers ?? const <AdminDriverListItem>[];
    var filteredDrivers = _applyLocalFilters(allDrivers);
    if (filteredDrivers.length > _pageSize) {
      filteredDrivers = filteredDrivers.take(_pageSize).toList();
    }
    final showNoData = !_loading && filteredDrivers.isEmpty;

    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F7),
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
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(cardPadding),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.surfaceVariant),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Drivers",
                            style: GoogleFonts.roboto(
                              fontSize: fsSection,
                              height: 24 / 18,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          InkWell(
                            onTap: () => context.push('/admin/drivers/add'),
                            borderRadius: BorderRadius.circular(12),
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: padding * 1.2,
                                vertical: spacing,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.onSurface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add,
                                    size: iconSize,
                                    color: colorScheme.surface,
                                  ),
                                  SizedBox(width: spacing / 2),
                                  Text(
                                    "New",
                                    style: GoogleFonts.roboto(
                                      fontSize: fsMain,
                                      height: 20 / 14,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.surface,
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
                          style: GoogleFonts.roboto(
                            fontSize: fsMain,
                            height: 20 / 14,
                            color: colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: "Search name, email, status, location...",
                            hintStyle: GoogleFonts.roboto(
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
                                    setState(() => selectedTab = value);
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
                                          style: GoogleFonts.roboto(
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
                                    setState(() => _pageSize = value);
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
                                              style: GoogleFonts.roboto(
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
                                  onTap: _loadDrivers,
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
                                          style: GoogleFonts.roboto(
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
                                    _errorShown
                                        ? "Couldn't load drivers."
                                        : "No drivers found",
                                    style: GoogleFonts.roboto(
                                      fontSize: fsSecondary,
                                      height: 16 / 12,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (_errorShown)
                                  TextButton(
                                    onPressed: _loadDrivers,
                                    child: const Text('Retry'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      if (_loading)
                        ...List<Widget>.generate(
                          3,
                          (index) => _buildDriverSkeletonCard(
                            padding: padding,
                            spacing: spacing,
                            cardPadding: cardPadding,
                            screenWidth: screenWidth,
                            bodyFs: fsMain,
                            smallFs: fsMeta,
                          ),
                        ),
                      if (!showNoData && !_loading)
                        ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredDrivers.length,
                          itemBuilder: (context, index) {
                            final driver = filteredDrivers[index];
                            return _buildDriverCardBody(
                              driver: driver,
                              colorScheme: colorScheme,
                              width: screenWidth,
                              spacing: spacing,
                              fsMain: fsMain,
                              fsSecondary: fsSecondary,
                              fsMeta: fsMeta,
                              iconSize: iconSize,
                              cardPadding: cardPadding,
                              padding: padding,
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
              title: 'Drivers',
              leadingIcon: Icons.badge,
              onClose: () => context.go('/admin/home'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverSkeletonCard({
    required double padding,
    required double spacing,
    required double cardPadding,
    required double screenWidth,
    required double bodyFs,
    required double smallFs,
  }) {
    final avatarSize = AdaptiveUtils.getAvatarSize(screenWidth);

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
                    width: avatarSize,
                    height: avatarSize,
                    radius: avatarSize / 2,
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

  Widget _buildDriverCardBody({
    required AdminDriverListItem driver,
    required ColorScheme colorScheme,
    required double width,
    required double spacing,
    required double fsMain,
    required double fsSecondary,
    required double fsMeta,
    required double iconSize,
    required double cardPadding,
    required double padding,
  }) {
    final driverId = driver.id.trim();
    final isUpdating = _updating[driverId] == true;

    final name = _safe(driver.fullName);
    final username = _safe(driver.username);
    final phone = _safe(driver.fullPhone);
    final email = _safe(driver.email);
    final address = _safe(driver.addressLocation);
    final primaryUser = _safe(driver.primaryUserName);
    final createdAt = _formatDateOnly(driver.raw['createdAt']?.toString());
    final enabled = driver.isActive;
    final initials = _initials(name);

    return Container(
      margin: EdgeInsets.only(bottom: padding),
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
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(25),
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            onTap: driverId.isEmpty
                ? null
                : () => context.push('/admin/drivers/details/$driverId'),
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
                        radius: AdaptiveUtils.getAvatarSize(width) / 2,
                        foregroundColor: colorScheme.onSurface,
                        child: Container(
                          width: AdaptiveUtils.getAvatarSize(width),
                          height: AdaptiveUtils.getAvatarSize(width),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.onSurface.withOpacity(0.12),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: GoogleFonts.roboto(
                              color: colorScheme.onSurface,
                              fontSize:
                                  AdaptiveUtils.getFsAvatarFontSize(width),
                              fontWeight: FontWeight.bold,
                            ),
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
                                    name,
                                    style: GoogleFonts.roboto(
                                      fontSize: fsMain,
                                      height: 20 / 14,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                    softWrap: true,
                                  ),
                                ),
                                Transform.scale(
                                  scale: 0.75,
                                  child: Switch(
                                    value: enabled,
                                    onChanged: isUpdating
                                        ? null
                                        : (v) => _toggleDriverActive(
                                              driver!,
                                              v,
                                            ),
                                    activeColor: colorScheme.onPrimary,
                                    activeTrackColor: colorScheme.primary,
                                    inactiveThumbColor: colorScheme.onPrimary,
                                    inactiveTrackColor:
                                        colorScheme.primary.withOpacity(0.3),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing / 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: iconSize,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: Text(
                                    username,
                                    style: GoogleFonts.roboto(
                                      fontSize: fsSecondary,
                                      height: 16 / 12,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                    softWrap: true,
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
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: Text(
                                    email,
                                    style: GoogleFonts.roboto(
                                      fontSize: fsSecondary,
                                      height: 16 / 12,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                    softWrap: true,
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
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: Text(
                                    phone,
                                    style: GoogleFonts.roboto(
                                      fontSize: fsSecondary,
                                      height: 16 / 12,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                    softWrap: true,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing / 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.verified_user_outlined,
                                  size: iconSize,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: Text(
                                    primaryUser,
                                    style: GoogleFonts.roboto(
                                      fontSize: fsSecondary,
                                      height: 16 / 12,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                    softWrap: true,
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
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: padding,
                      vertical: spacing,
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
                        Text(
                          "Location",
                          style: GoogleFonts.roboto(
                            fontSize: fsMeta,
                            height: 14 / 11,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        SizedBox(height: spacing / 2),
                        Text(
                          address,
                          softWrap: true,
                          style: GoogleFonts.roboto(
                            fontSize: fsSecondary,
                            height: 16 / 12,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
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
                              "Joined",
                              style: GoogleFonts.roboto(
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
                          createdAt,
                          style: GoogleFonts.roboto(
                            fontSize: fsMain,
                            height: 20 / 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          softWrap: true,
                        ),
                    ],
                  ),
                ),
                SizedBox(height: spacing),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: padding,
                    vertical: spacing * 1.6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chevron_right,
                        size: iconSize,
                        color: colorScheme.onPrimary,
                      ),
                      SizedBox(width: spacing),
                      Text(
                        "View",
                        style: GoogleFonts.roboto(
                          fontSize: fsMain,
                          height: 20 / 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimary,
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
      ),
    );
  }
}
