// screens/vehicles/vehicle_screen.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/vehicle_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  String selectedTab = "All";
  final TextEditingController _searchController = TextEditingController();

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
    final double titleFs = AdaptiveUtils.getTitleFontSize(width);
    final double bodyFs = titleFs - 1;
    final double smallFs = titleFs - 3;
    final double iconSize = titleFs + 2;
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

    final showNoData = !_loadingVehicles && filteredVehicles.isEmpty;
    final showSkeletonCards = _loadingVehicles;

    return AppLayout(
      title: "SUPER ADMIN",
      subtitle: "Vehicles",
      actionIcons: const [CupertinoIcons.add],
      leftAvatarText: 'SA',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SEARCH BAR
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
                  hintText: "Search plate, type, user, IMEI...",
                  hintStyle: GoogleFonts.inter(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: bodyFs,
                  ),
                  prefixIcon: Icon(
                    CupertinoIcons.search,
                    size: iconSize,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: hp,
                    vertical: hp,
                  ),
                ),
              ),
            ),
            SizedBox(height: hp),

            // TABS
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: ["All", "Active", "Inactive"].map((tab) {
                return SmallTab(
                  label: tab,
                  selected: selectedTab == tab,
                  onTap: () => setState(() => selectedTab = tab),
                );
              }).toList(),
            ),
            SizedBox(height: hp),

            // COUNT + ADD BUTTON
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _loadingVehicles
                    ? AppShimmer(
                        width: width * 0.45,
                        height: bodyFs + 10,
                        radius: 8,
                      )
                    : Text(
                        "Showing ${filteredVehicles.length} of ${_vehicles.length} vehicles",
                        style: GoogleFonts.inter(
                          fontSize: bodyFs,
                          color: colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                GestureDetector(
                  onTap: () => context.push("/superadmin/vehicles/add"),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: hp * 1.5,
                      vertical: spacing,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Add Vehicle",
                      style: GoogleFonts.inter(
                        fontSize: bodyFs - 3,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 1.5),

            if (showNoData && _vehiclesLoadFailed)
              Padding(
                padding: EdgeInsets.symmetric(vertical: hp),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Couldn\'t load vehicles.',
                        style: GoogleFonts.inter(
                          fontSize: bodyFs,
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
                child: Text(
                  'No vehicles found.',
                  style: GoogleFonts.inter(
                    fontSize: bodyFs,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
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
                  bodyFs: bodyFs,
                  smallFs: smallFs,
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
                final primaryInitials = _safeAny(
                  vehicle["primary_user_initials"],
                );
                final primaryName = _safeAny(vehicle["primary_user_name"]);
                final primaryUsername = _safeAny(
                  vehicle["primary_user_username"],
                );
                final addedByInitials = _safeAny(vehicle["added_by_initials"]);
                final addedByName = _safeAny(vehicle["added_by_name"]);
                final addedByUsername = _safeAny(vehicle["added_by_username"]);
                final lastSeenDate = _safeAny(vehicle["last_activity_date"]);
                final lastSeenTime = _safeAny(vehicle["last_activity_time"]);
                final createdDate = _safeAny(vehicle["created_date"]);
                final createdTime = _safeAny(vehicle["created_time"]);
                final isActive = vehicle["active"] == true;
                final displayTitle = name == '-' ? type : name;

                final licensePri = _safeAny(vehicle["license_pri"]);
                final licenseSec = _safeAny(vehicle["license_sec"]);
                final priDate = _tryParseAnyDate(licensePri);
                final secDate = _tryParseAnyDate(licenseSec);
                final isPriExpiring =
                    priDate != null && priDate.difference(now).inDays < 30;
                final isSecExpiring =
                    secDate != null && secDate.difference(now).inDays < 30;
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
                        onTap: () async {
                          final result = await context.push<bool>(
                            "/superadmin/vehicles/details/${vehicle['id']}",
                          );
                          if (!context.mounted) return;
                          if (result == true) {
                            await _loadVehicles();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vehicle deleted')),
                            );
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.all(cardPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // TOP ROW
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: AdaptiveUtils.getAvatarSize(width),
                                    height: AdaptiveUtils.getAvatarSize(width),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colorScheme.outline.withOpacity(
                                          0.3,
                                        ),
                                      ),
                                    ),
                                    child: Icon(
                                      CupertinoIcons.car_detailed,
                                      size: AdaptiveUtils.getFsAvatarFontSize(
                                        width,
                                      ),
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  SizedBox(width: spacing * 1.5),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      plate,
                                                      style: GoogleFonts.inter(
                                                        fontSize: bodyFs + 2,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: colorScheme
                                                            .onSurface,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      softWrap: false,
                                                    ),
                                                  ),
                                                  SizedBox(width: spacing),
                                                  Flexible(
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal:
                                                                spacing + 4,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: isActive
                                                            ? colorScheme
                                                                  .primary
                                                                  .withOpacity(
                                                                    0.15,
                                                                  )
                                                            : colorScheme.error
                                                                  .withOpacity(
                                                                    0.15,
                                                                  ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              16,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        status,
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: smallFs,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: isActive
                                                                  ? colorScheme
                                                                        .primary
                                                                  : colorScheme
                                                                        .error,
                                                            ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        softWrap: false,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: spacing),
                                            Flexible(
                                              child: Text(
                                                displayTitle,
                                                style: GoogleFonts.inter(
                                                  fontSize: smallFs + 2,
                                                  fontWeight: FontWeight.w600,
                                                  color: colorScheme.onSurface
                                                      .withOpacity(0.87),
                                                ),
                                                maxLines: 1,
                                                textAlign: TextAlign.end,
                                                overflow: TextOverflow.ellipsis,
                                                softWrap: false,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: spacing / 2),
                                        Row(
                                          children: [
                                            Icon(
                                              CupertinoIcons
                                                  .device_phone_portrait,
                                              size: iconSize,
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.6),
                                            ),
                                            SizedBox(width: spacing),
                                            Expanded(
                                              child: Text(
                                                imei,
                                                style: GoogleFonts.inter(
                                                  fontSize: bodyFs,
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
                                        SizedBox(height: spacing / 2),
                                        Padding(
                                          padding: EdgeInsets.only(
                                            left: iconSize + spacing,
                                          ),
                                          child: Text(
                                            "Type: $type • VIN: $vin • SIM: $simNumber",
                                            style: GoogleFonts.inter(
                                              fontSize: bodyFs - 1,
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.7),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: spacing * 2),

                              // PRIMARY USER & ADDED BY
                              Row(
                                children: [
                                  Expanded(
                                    child: _userInfo(
                                      "Primary User",
                                      primaryInitials,
                                      primaryName,
                                      primaryUsername,
                                      width,
                                      colorScheme,
                                      spacing,
                                      bodyFs,
                                      smallFs,
                                    ),
                                  ),
                                  Expanded(
                                    child: _userInfo(
                                      "Added by",
                                      addedByInitials,
                                      addedByName,
                                      addedByUsername,
                                      width,
                                      colorScheme,
                                      spacing,
                                      bodyFs,
                                      smallFs,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: spacing * 2),

                              // LAST SEEN + SWITCH
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Last Seen: $lastSeenDate $lastSeenTime",
                                      style: GoogleFonts.inter(
                                        fontSize: smallFs + 1,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.87),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                    ),
                                  ),
                                  Transform.scale(
                                    scale: 0.85,
                                    child: Switch(
                                      value: isActive,
                                      activeColor: colorScheme.onPrimary,
                                      activeTrackColor: colorScheme.primary,
                                      inactiveThumbColor:
                                          colorScheme.onSurfaceVariant,
                                      inactiveTrackColor:
                                          colorScheme.surfaceVariant,
                                      onChanged: (v) => setState(() {
                                        vehicle["active"] = v;
                                        vehicle["status"] = v
                                            ? "Active"
                                            : "Inactive";
                                      }),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: spacing),

                              // LICENSE INFO
                              Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.doc_checkmark_fill,
                                    size: iconSize,
                                    color: colorScheme.primary,
                                  ),
                                  SizedBox(width: spacing),
                                  Expanded(
                                    child: Text(
                                      "Primary: $licensePri ${priStatus.isEmpty ? '' : priStatus}",
                                      style: GoogleFonts.inter(
                                        fontSize: bodyFs - 1,
                                        color: isPriExpiring
                                            ? colorScheme.error
                                            : colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      "Secondary: $licenseSec ${secStatus.isEmpty ? '' : secStatus}",
                                      textAlign: TextAlign.end,
                                      style: GoogleFonts.inter(
                                        fontSize: bodyFs - 1,
                                        color: isSecExpiring
                                            ? colorScheme.error
                                            : colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: spacing),
                              Divider(
                                color: colorScheme.outline.withOpacity(0.3),
                              ),
                              SizedBox(height: spacing),
                              Text(
                                "Created: $createdDate $createdTime",
                                style: GoogleFonts.inter(
                                  fontSize: smallFs,
                                  color: colorScheme.onSurface.withOpacity(
                                    0.54,
                                  ),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),

            SizedBox(height: hp * 3),
          ],
        ),
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
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: scheme.primary,
          child: Text(
            initials,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: scheme.onPrimary,
            ),
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: smallFs - 1,
                  color: scheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: bodyFs,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
              Text(
                username,
                style: GoogleFonts.inter(
                  fontSize: smallFs,
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
