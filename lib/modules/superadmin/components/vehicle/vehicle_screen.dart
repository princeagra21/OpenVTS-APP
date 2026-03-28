// screens/vehicles/vehicle_screen.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/vehicle_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/components/appbars/superadmin_home_appbar.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/superadmin/utils/app_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  String selectedTab = "All";
  final TextEditingController _searchController = TextEditingController();
  int _pageSize = 10;

  bool _loadingVehicles = false;
  bool _vehiclesErrorShown = false;
  CancelToken? _vehiclesCancelToken;
  ApiClient? _api;
  SuperadminRepository? _repo;

  DateTime _safeParseDate(String dateStr) {
    try {
      return DateFormat('dd MMM yyyy').parse(dateStr);
    } catch (e) {
      try {
        return DateTime.parse(dateStr);
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  final List<Map<String, dynamic>> _vehicles = <Map<String, dynamic>>[];
  bool _vehiclesLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadVehicles();
  }

  @override
  void dispose() {
    _vehiclesCancelToken?.cancel('VehicleScreen disposed');
    _searchController.dispose();
    super.dispose();
  }

  DateTime _tryParseUpdatedAt(String s) =>
      DateTime.tryParse(s) ?? DateTime.now();

  String safe(String? v) {
    if (v == null) return '-';
    final t = v.trim();
    return t.isEmpty ? '-' : t;
  }

  String _safeAny(Object? v) => safe(v?.toString());

  String _initials(String name) {
    final parts = safe(name).split(RegExp(r'\s+'));
    if (parts.isEmpty) return '—';
    final out = parts.where((p) => p.isNotEmpty).take(2).map((p) => p[0]);
    final initials = out.join();
    return initials.isEmpty ? '—' : initials.toUpperCase();
  }

  DateTime? _tryParseAnyDate(String input) {
    final value = input.trim();
    if (value.isEmpty || value == '-') return null;
    final parsedIso = DateTime.tryParse(value);
    if (parsedIso != null) return parsedIso;
    try {
      return DateFormat('dd MMM yyyy').parseStrict(value);
    } catch (_) {
      return null;
    }
  }

  String _firstNonEmpty(List<String> candidates) {
    for (final value in candidates) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  String _formatDateLabel(String raw) {
    final dt = _tryParseAnyDate(raw);
    if (dt == null) return safe(raw);
    return DateFormat('dd MMM yyyy').format(dt);
  }

  Map<String, dynamic> _mapVehicleItem(VehicleListItem v) {
    final now = DateTime.now();
    final raw = v.raw;
    final activityRaw = _firstNonEmpty([v.updatedAt, v.createdAt]);
    final createdRaw = _firstNonEmpty([v.createdAt, v.updatedAt]);
    final activityAt = activityRaw.isNotEmpty
        ? _tryParseUpdatedAt(activityRaw)
        : now;
    final createdAt = createdRaw.isNotEmpty
        ? _tryParseUpdatedAt(createdRaw)
        : activityAt;

    final plate = safe(v.plateNumber);
    final name = safe(v.name);
    final vin = safe(v.vin);
    final imei = safe(v.imei);
    final simNumber = safe(v.simNumber);
    final primaryName = safe(
      v.userPrimaryName.isNotEmpty ? v.userPrimaryName : v.driverName,
    );
    final addedByName = safe(v.userAddedByName);
    final primaryUsername = safe(v.userPrimaryUsername);
    final addedByUsername = safe(v.userAddedByUsername);
    final isActive = v.isActive;
    final status = safe(
      v.status.isNotEmpty ? v.status : (isActive ? 'Active' : 'Inactive'),
    );
    final motion = safe(
      raw['motion']?.toString() ??
          raw['movement']?.toString() ??
          raw['movementStatus']?.toString(),
    );
    final speed = safe(raw['speed']?.toString() ?? raw['speedKph']?.toString());
    final engine = safe(
      raw['engine']?.toString() ??
          raw['engineStatus']?.toString() ??
          raw['ignition']?.toString() ??
          raw['ignitionStatus']?.toString(),
    );
    final licensePri = _formatDateLabel(v.primaryExpiry);
    final licenseSec = _formatDateLabel(v.secondaryExpiry);
    final timezone = safe(v.gmtOffset);

    return <String, dynamic>{
      "id": safe(v.id),
      "name": name,
      "vin": vin,
      "plate": plate,
      "type": safe(v.type.isNotEmpty ? v.type : "Vehicle"),
      "imei": imei,
      "sim_number": simNumber,
      "primary_user_initials": _initials(primaryName),
      "primary_user_name": primaryName,
      "primary_user_username": primaryUsername,
      "added_by_initials": _initials(addedByName),
      "added_by_name": addedByName,
      "added_by_username": addedByUsername,
      "motion": motion,
      "speed": speed,
      "engine": engine,
      "created_date": DateFormat('dd MMM yyyy').format(createdAt),
      "created_time": DateFormat('HH:mm').format(createdAt),
      "license_pri": licensePri,
      "license_sec": licenseSec,
      "last_activity_date": DateFormat('dd MMM yyyy').format(activityAt),
      "last_activity_time": DateFormat('HH:mm').format(activityAt),
      "status": status,
      "active": isActive,
      "timezone": timezone,
    };
  }

  Future<void> _loadVehicles() async {
    _vehiclesCancelToken?.cancel('Reload vehicles');
    final token = CancelToken();
    _vehiclesCancelToken = token;

    if (!mounted) return;
    setState(() => _loadingVehicles = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      if (kDebugMode) {
        final url =
            '${_api!.dio.options.baseUrl}/superadmin/vehicles?page=1&limit=50';
        debugPrint('[Vehicles] endpoint=$url');
      }

      final res = await _repo!.getVehicles(
        page: 1,
        limit: 50,
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (items) {
          if (kDebugMode) {
            debugPrint('[Vehicles] status=200 vehicles=${items.length}');
          }
          if (!mounted) return;
          final mapped = items.map(_mapVehicleItem).toList();
          setState(() {
            _loadingVehicles = false;
            _vehiclesErrorShown = false;
            _vehiclesLoadFailed = false;
            _vehicles
              ..clear()
              ..addAll(mapped);
          });
        },
        failure: (err) {
          if (kDebugMode) {
            final status = err is ApiException ? err.statusCode : null;
            debugPrint('[Vehicles] status=${status ?? 'error'} vehicles=0');
          }
          if (!mounted) return;
          setState(() {
            _loadingVehicles = false;
            _vehiclesLoadFailed = true;
          });
          if (_vehiclesErrorShown) return;
          _vehiclesErrorShown = true;

          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to view vehicles.'
              : "Couldn't load vehicles.";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () {
                  _vehiclesErrorShown = false;
                  _loadVehicles();
                },
              ),
            ),
          );
        },
      );
    } catch (_) {
      if (kDebugMode) {
        debugPrint('[Vehicles] status=error vehicles=0');
      }
      if (!mounted) return;
      setState(() {
        _loadingVehicles = false;
        _vehiclesLoadFailed = true;
      });
      if (_vehiclesErrorShown) return;
      _vehiclesErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Couldn't load vehicles."),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () {
              _vehiclesErrorShown = false;
              _loadVehicles();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double fsSection = 18 * scale;
    final double fsMain = 14 * scale;
    final double fsSecondary = 12 * scale;
    final double fsMeta = 11 * scale;
    final double iconSize = 16 * scale;
    final double smallIcon = 14 * scale;
    final double cardPadding = hp + 4;

    final searchQuery = _searchController.text.toLowerCase();
    final now = DateTime.now();

    var filteredVehicles =
        _vehicles.where((v) {
          final matchesSearch =
              searchQuery.isEmpty ||
              _safeAny(v['plate']).toLowerCase().contains(searchQuery) ||
              _safeAny(v['name']).toLowerCase().contains(searchQuery) ||
              _safeAny(v['vin']).toLowerCase().contains(searchQuery) ||
              _safeAny(v['sim_number']).toLowerCase().contains(searchQuery) ||
              _safeAny(v['type']).toLowerCase().contains(searchQuery) ||
              _safeAny(v['imei']).toLowerCase().contains(searchQuery) ||
              _safeAny(
                v['primary_user_name'],
              ).toLowerCase().contains(searchQuery) ||
              _safeAny(v['added_by_name']).toLowerCase().contains(searchQuery);

          final matchesTab =
              selectedTab == "All" ||
              (selectedTab == "Active" && v['active'] == true) ||
              (selectedTab == "Inactive" && v['active'] == false);

          return matchesSearch && matchesTab;
        }).toList()..sort(
          (a, b) => _safeParseDate(
            _safeAny(b['last_activity_date']),
          ).compareTo(_safeParseDate(_safeAny(a['last_activity_date']))),
        );
    if (filteredVehicles.length > _pageSize) {
      filteredVehicles = filteredVehicles.take(_pageSize).toList();
    }

    final showNoData = !_loadingVehicles && filteredVehicles.isEmpty;
    final showSkeletonCards = _loadingVehicles;

    final topPadding = MediaQuery.of(context).padding.top;
    final horizontalPadding = AdaptiveUtils.isVerySmallScreen(width)
        ? 8.0
        : AdaptiveUtils.isSmallScreen(width)
            ? 10.0
            : 12.0;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding + AppUtils.appBarHeightCustom + 28,
              horizontalPadding,
              84,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // SEARCH BAR
            // Container(
            //   height: hp * 3.5,
            //   decoration: BoxDecoration(
            //     color: colorScheme.surfaceVariant,
            //     borderRadius: BorderRadius.circular(24),
            //     boxShadow: [
            //       BoxShadow(
            //         color: Colors.black.withOpacity(0.05),
            //         blurRadius: 6,
            //         offset: const Offset(0, 3),
            //       ),
            //     ],
            //   ),
            //   child: TextField(
            //     controller: _searchController,
            //     style: GoogleFonts.inter(
            //       fontSize: bodyFs,
            //       color: colorScheme.onSurface,
            //     ),
            //     decoration: InputDecoration(
            //       hintText: "Search plate, type, user, IMEI...",
            //       hintStyle: GoogleFonts.inter(
            //         color: colorScheme.onSurface.withOpacity(0.6),
            //         fontSize: bodyFs,
            //       ),
            //       prefixIcon: Icon(
            //         CupertinoIcons.search,
            //         size: iconSize,
            //         color: colorScheme.onSurface.withOpacity(0.7),
            //       ),
            //       border: InputBorder.none,
            //       contentPadding: EdgeInsets.symmetric(
            //         horizontal: hp,
            //         vertical: hp,
            //       ),
            //     ),
            //   ),
            // ),
            // SizedBox(height: hp),

            // SUMMARY HEADER
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: hp * 0.9,
                vertical: hp * 0.7,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "All Vehicles",
                    style: GoogleFonts.inter(
                      fontSize: fsSection,
                      height: 24 / 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _vehicles.isEmpty
                        ? "No vehicles across your administrators."
                        : "${_vehicles.length} vehicle(s) across all administrators",
                    style: GoogleFonts.inter(
                      fontSize: fsSecondary,
                      height: 16 / 12,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: spacing * 0.6),
                ],
              ),
            ),
            SizedBox(height: spacing * 1.5),

            // BROWSE VEHICLES
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(cardPadding),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: colorScheme.surfaceVariant),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Browse Vehicles",
                        style: GoogleFonts.inter(
                          fontSize: fsSection,
                          height: 24 / 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing),
                  Container(
                    height: hp * 3.5,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.1),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.inter(
                        fontSize: fsMain,
                        height: 20 / 14,
                        color: colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: "Search plate, type, user, IMEI...",
                        hintStyle: GoogleFonts.inter(
                          color: colorScheme.onSurface.withOpacity(0.5),
                          fontSize: fsSecondary,
                          height: 16 / 12,
                        ),
                        prefixIcon: Icon(
                          CupertinoIcons.search,
                          size: iconSize,
                          color: colorScheme.onSurface,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: hp,
                          vertical: hp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: spacing),
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
                                  horizontal: hp,
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.tune,
                                      size: iconSize,
                                      color: colorScheme.onSurface,
                                    ),
                                    SizedBox(width: spacing / 2),
                                    Text(
                                      "Filter",
                                      style: GoogleFonts.inter(
                                        fontSize: fsMain,
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
                                  horizontal: hp,
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Records",
                                      style: GoogleFonts.inter(
                                        fontSize: fsMain,
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
                              ),
                            ),
                          ),
                          SizedBox(
                            width: cellWidth,
                            child: InkWell(
                              onTap: () {},
                              borderRadius: BorderRadius.circular(12),
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: hp,
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.download_outlined,
                                      size: iconSize,
                                      color: colorScheme.onSurface,
                                    ),
                                    SizedBox(width: spacing / 2),
                                    Text(
                                      "Export",
                                      style: GoogleFonts.inter(
                                        fontSize: fsMain,
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
                ],
              ),
            ),
            SizedBox(height: spacing * 1.5),

            Container(
              width: double.infinity,
              padding: EdgeInsets.all(cardPadding),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: colorScheme.surfaceVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showNoData && _vehiclesLoadFailed)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: hp),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Couldn\'t load vehicles.',
                              style: GoogleFonts.inter(
                                fontSize: fsSecondary,
                                height: 16 / 12,
                                color: colorScheme.onSurface.withOpacity(0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ),
                          SizedBox(width: spacing),
                          TextButton(
                            onPressed: _loadVehicles,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  if (showNoData && !_vehiclesLoadFailed)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: hp),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No vehicles found',
                            style: GoogleFonts.inter(
                              fontSize: fsMain,
                              height: 20 / 14,
                              color: colorScheme.onSurface.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ask superadmin to assign vehicles.',
                            style: GoogleFonts.inter(
                              fontSize: fsSecondary,
                              height: 16 / 12,
                              color: colorScheme.onSurface.withOpacity(0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (showSkeletonCards)
                    ...List<Widget>.generate(
                      3,
                      (index) => _buildVehicleSkeletonCard(
                        index: index,
                        hp: hp,
                        spacing: spacing,
                        cardPadding: cardPadding,
                        width: width,
                        iconSize: iconSize,
                        bodyFs: fsMain,
                        smallFs: fsMeta,
                        colorScheme: colorScheme,
                      ),
                    ),
                  if (!showNoData && !showSkeletonCards)
                    // VEHICLE CARDS
                    ...filteredVehicles.asMap().entries.map((entry) {
                      final index = entry.key;
                      final vehicle = entry.value;

                      final plate = _safeAny(vehicle["plate"]);
                      final name = _safeAny(vehicle["name"]);
                      final type = _safeAny(vehicle["type"]);
                      final vin = _safeAny(vehicle["vin"]);
                      final imei = _safeAny(vehicle["imei"]);
                      final simNumber = _safeAny(vehicle["sim_number"]);
                      final status = _safeAny(vehicle["status"]);
                      final primaryName = _safeAny(
                        vehicle["primary_user_name"],
                      );
                      final addedByName = _safeAny(vehicle["added_by_name"]);
                      final lastSeenDate = _safeAny(
                        vehicle["last_activity_date"],
                      );
                      final lastSeenTime = _safeAny(
                        vehicle["last_activity_time"],
                      );
                      final createdDate = _safeAny(vehicle["created_date"]);
                      final createdTime = _safeAny(vehicle["created_time"]);
                      final isActive = vehicle["active"] == true;
                      final displayTitle = name == '-' ? type : name;

                      final licensePri = _safeAny(vehicle["license_pri"]);
                      final licenseSec = _safeAny(vehicle["license_sec"]);
                      final priDate = _tryParseAnyDate(licensePri);
                      final secDate = _tryParseAnyDate(licenseSec);
                      final isPriExpiring = priDate != null &&
                          priDate.difference(now).inDays < 30;
                      final isSecExpiring = secDate != null &&
                          secDate.difference(now).inDays < 30;
                      final priStatus = priDate == null
                          ? ''
                          : (isPriExpiring ? '(Expiring soon)' : '(Valid)');
                      final secStatus = secDate == null
                          ? ''
                          : (isSecExpiring ? '(Expiring soon)' : '(Valid)');

                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300 + index * 50),
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
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            onTap: null,
                            // onTap: () async {
                            //   final result = await context.push<bool>(
                            //     "/superadmin/vehicles/details/${vehicle['id']}",
                            //   );
                            //   if (!context.mounted) return;
                            //   if (result == true) {
                            //     await _loadVehicles();
                            //     if (!context.mounted) return;
                            //     ScaffoldMessenger.of(context).showSnackBar(
                            //       const SnackBar(
                            //         content: Text('Vehicle deleted'),
                            //       ),
                            //     );
                            //   }
                            // },
                              child: Padding(
                                padding: EdgeInsets.all(cardPadding),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // TOP ROW
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 40 * scale,
                                          height: 40 * scale,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            color: Theme.of(context)
                                                        .brightness ==
                                                    Brightness.dark
                                                ? colorScheme.surfaceVariant
                                                : Colors.grey.shade50,
                                            border: Border.all(
                                              color: colorScheme.outline
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            CupertinoIcons.car_detailed,
                                            size: 18 * scale,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                        SizedBox(width: spacing * 1.5),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                displayTitle,
                                                style: GoogleFonts.inter(
                                                  fontSize: fsMain,
                                                  height: 20 / 14,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      colorScheme.onSurface,
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                softWrap: false,
                                              ),
                                              SizedBox(height: spacing * 0.4),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: spacing + 4,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? (isActive
                                                          ? colorScheme.primary
                                                              .withOpacity(
                                                                0.15,
                                                              )
                                                          : colorScheme.error
                                                              .withOpacity(
                                                                0.15,
                                                              ))
                                                      : Colors.grey.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    16,
                                                  ),
                                                ),
                                                child: Text(
                                                  plate,
                                                  style: GoogleFonts.inter(
                                                    fontSize: fsMeta,
                                                    height: 14 / 11,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color:
                                                        Theme.of(context)
                                                                    .brightness ==
                                                                Brightness.dark
                                                            ? (isActive
                                                                ? colorScheme
                                                                    .primary
                                                                : colorScheme
                                                                    .error)
                                                            : colorScheme
                                                                .onSurface,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  softWrap: false,
                                                ),
                                              ),
                                              SizedBox(height: spacing * 0.4),
                                              Text(
                                                type,
                                                style: GoogleFonts.inter(
                                                  fontSize: fsSecondary,
                                                  height: 16 / 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: colorScheme.onSurface
                                                      .withOpacity(0.7),
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                softWrap: false,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: spacing + 4,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                        .brightness ==
                                                    Brightness.dark
                                                ? (isActive
                                                    ? colorScheme.primary
                                                        .withOpacity(0.15)
                                                    : colorScheme.error
                                                        .withOpacity(0.15))
                                                : Colors.grey.shade50,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isActive
                                                    ? Icons.check_circle
                                                    : Icons.cancel,
                                                size: fsMeta + 2,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? (isActive
                                                        ? colorScheme.primary
                                                        : colorScheme.error)
                                                    : colorScheme.onSurface,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                status,
                                                style: GoogleFonts.inter(
                                                  fontSize: fsMeta,
                                                  height: 14 / 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? (isActive
                                                          ? colorScheme.primary
                                                          : colorScheme.error)
                                                      : colorScheme.onSurface,
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                softWrap: false,
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
                                              color: colorScheme.surface,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: colorScheme.onSurface
                                                    .withOpacity(0.1),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Symbols.memory,
                                                      size: iconSize,
                                                      color: colorScheme
                                                          .onSurface
                                                          .withOpacity(0.7),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      "IMEI",
                                                      style: GoogleFonts.inter(
                                                        fontSize: fsMeta,
                                                        height: 14 / 11,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: colorScheme
                                                            .onSurface
                                                            .withOpacity(0.7),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: spacing),
                                                Text(
                                                  imei,
                                                  style: GoogleFonts.inter(
                                                    fontSize: fsMain,
                                                    height: 20 / 14,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color:
                                                        colorScheme.onSurface,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  softWrap: false,
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
                                              color: colorScheme.surface,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: colorScheme.onSurface
                                                    .withOpacity(0.1),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Symbols.memory,
                                                      size: iconSize,
                                                      color: colorScheme
                                                          .onSurface
                                                          .withOpacity(0.7),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      "SIM",
                                                      style: GoogleFonts.inter(
                                                        fontSize: fsMeta,
                                                        height: 14 / 11,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: colorScheme
                                                            .onSurface
                                                            .withOpacity(0.7),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: spacing),
                                                Text(
                                                  simNumber,
                                                  style: GoogleFonts.inter(
                                                    fontSize: fsMain,
                                                    height: 20 / 14,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color:
                                                        colorScheme.onSurface,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  softWrap: false,
                                                ),
                                              ],
                                            ),
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
                                              color: colorScheme.surface,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: colorScheme.onSurface
                                                    .withOpacity(0.1),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.person_outline,
                                                      size: iconSize,
                                                      color: colorScheme
                                                          .onSurface
                                                          .withOpacity(0.7),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      "Primary",
                                                      style: GoogleFonts.inter(
                                                        fontSize: fsMeta,
                                                        height: 14 / 11,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: colorScheme
                                                            .onSurface
                                                            .withOpacity(0.7),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: spacing),
                                                Text(
                                                  primaryName,
                                                  style: GoogleFonts.inter(
                                                    fontSize: fsMain,
                                                    height: 20 / 14,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color:
                                                        colorScheme.onSurface,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  softWrap: false,
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
                                              color: colorScheme.surface,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: colorScheme.onSurface
                                                    .withOpacity(0.1),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.person_add_outlined,
                                                      size: iconSize,
                                                      color: colorScheme
                                                          .onSurface
                                                          .withOpacity(0.7),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      "Added By",
                                                      style: GoogleFonts.inter(
                                                        fontSize: fsMeta,
                                                        height: 14 / 11,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: colorScheme
                                                            .onSurface
                                                            .withOpacity(0.7),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: spacing),
                                                Text(
                                                  addedByName,
                                                  style: GoogleFonts.inter(
                                                    fontSize: fsMain,
                                                    height: 20 / 14,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color:
                                                        colorScheme.onSurface,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  softWrap: false,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: spacing),
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: spacing * 1.2,
                                        vertical: spacing - 2,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.event_outlined,
                                                size: iconSize,
                                                color: colorScheme.onSurface
                                                    .withOpacity(0.7),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                "Created",
                                                style: GoogleFonts.inter(
                                                  fontSize: fsMeta,
                                                  height: 14 / 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: colorScheme.onSurface
                                                      .withOpacity(0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: spacing),
                                          Text(
                                            createdDate,
                                            style: GoogleFonts.inter(
                                              fontSize: fsMain,
                                              height: 20 / 14,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                          ),
                                          SizedBox(height: spacing / 2),
                                          Text(
                                            createdTime,
                                            style: GoogleFonts.inter(
                                              fontSize: fsSecondary,
                                              height: 16 / 12,
                                              fontWeight: FontWeight.w500,
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.8),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                          ),
                                        ],
                                      ),
                                    ),
                                    /*
                                    SizedBox(height: spacing * 0.3),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "VIN: $vin",
                                            style: GoogleFonts.inter(
                                              fontSize: fsSecondary,
                                              height: 16 / 12,
                                              fontWeight: FontWeight.w500,
                                              color: colorScheme.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                          ),
                                        ),
                                        SizedBox(width: spacing),
                                        Expanded(
                                          child: Text(
                                            "Timezone: ${_safeAny(vehicle["timezone"])}",
                                            style: GoogleFonts.inter(
                                              fontSize: fsSecondary,
                                              height: 16 / 12,
                                              fontWeight: FontWeight.w500,
                                              color: colorScheme.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: spacing * 0.6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "Primary license: $licensePri $priStatus",
                                            style: GoogleFonts.inter(
                                              fontSize: fsSecondary,
                                              height: 16 / 12,
                                              fontWeight: FontWeight.w500,
                                              color: colorScheme.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                          ),
                                        ),
                                        SizedBox(width: spacing),
                                        Expanded(
                                          child: Text(
                                            "Secondary license: $licenseSec $secStatus",
                                            style: GoogleFonts.inter(
                                              fontSize: fsSecondary,
                                              height: 16 / 12,
                                              fontWeight: FontWeight.w500,
                                              color: colorScheme.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: spacing * 1.5),
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: spacing,
                                            vertical: spacing * 0.6,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: colorScheme.outline
                                                  .withOpacity(0.3),
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: RichText(
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: "Last seen: ",
                                                  style: GoogleFonts.inter(
                                                    fontSize: fsMeta,
                                                    height: 14 / 11,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    color: colorScheme.onSurface
                                                        .withOpacity(0.87),
                                                  ),
                                                ),
                                                TextSpan(
                                                  text:
                                                      "$lastSeenDate $lastSeenTime",
                                                  style: GoogleFonts.inter(
                                                    fontSize: fsSecondary,
                                                    height: 16 / 12,
                                                    fontWeight:
                                                        FontWeight.w500,
                                                    color: colorScheme.onSurface
                                                        .withOpacity(0.87),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: spacing,
                                            vertical: spacing * 0.8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.12),
                                                blurRadius: 10,
                                                spreadRadius: -4,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: fsMeta + 16,
                                                height: fsMeta + 16,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color:
                                                      colorScheme.surfaceVariant,
                                                  border: Border.all(
                                                    color:
                                                        colorScheme.onSurface
                                                            .withOpacity(0.2),
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.more_horiz,
                                                  size: smallIcon,
                                                  color:
                                                      colorScheme.onSurface,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "More",
                                                style: GoogleFonts.inter(
                                                  fontSize: fsMain,
                                                  height: 20 / 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: colorScheme.onSurface,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: spacing * 0.3),
                                    */
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
            SizedBox(height: hp * 3),
              ],
            ),
          ),
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            top: 0,
            child: SuperAdminHomeAppBar(
              title: 'Vehicles',
              leadingIcon: Symbols.sync_alt,
            ),
          ),
        ],
      ),
    );
  }

  Widget _userInfo(
    String label,
    String initials,
    String name,
    String username,
    double width,
    ColorScheme scheme,
    double spacing,
    double bodyFs,
    double smallFs,
  ) {
    final double scale = bodyFs / 14;
    final double labelFs = 11 * scale;
    final double titleFs = 14 * scale;
    final double subtitleFs = 12 * scale;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: labelFs,
                  height: 14 / 11,
                  color: scheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: titleFs,
                  height: 20 / 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
              Text(
                username,
                style: GoogleFonts.inter(
                  fontSize: subtitleFs,
                  height: 16 / 12,
                  color: scheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleSkeletonCard({
    required int index,
    required double hp,
    required double spacing,
    required double cardPadding,
    required double width,
    required double iconSize,
    required double bodyFs,
    required double smallFs,
    required ColorScheme colorScheme,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + index * 50),
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
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppShimmer(
                    width: AdaptiveUtils.getAvatarSize(width),
                    height: AdaptiveUtils.getAvatarSize(width),
                    radius: AdaptiveUtils.getAvatarSize(width),
                  ),
                  SizedBox(width: spacing * 1.5),
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
                          width: width * 0.35,
                          height: bodyFs + 8,
                          radius: 8,
                        ),
                        SizedBox(height: spacing),
                        AppShimmer(
                          width: width * 0.45,
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
                      height: iconSize + bodyFs + 8,
                      radius: 12,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: AppShimmer(
                      width: double.infinity,
                      height: iconSize + bodyFs + 8,
                      radius: 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing * 2),
              AppShimmer(width: width * 0.5, height: smallFs + 10, radius: 8),
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
}
