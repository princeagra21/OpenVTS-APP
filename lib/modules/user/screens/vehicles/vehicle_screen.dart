import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/vehicle_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_vehicles_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/user/layout/app_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  // FleetStack-API-Reference.md confirmed:
  // - GET /user/vehicles
  //
  // Safe field mapping used in UI:
  // - vehicle_no  <- plateNumber/name/id
  // - type        <- vehicleType.name/vehicleTypeName/type
  // - imei        <- imei/device.imei
  // - last_data   <- updatedAt/createdAt
  // - status      <- status/isActive with local normalization for Active/Expired/Suspended
  String selectedTab = 'All';
  final TextEditingController _searchController = TextEditingController();

  ApiClient? _apiClient;
  UserVehiclesRepository? _repo;
  CancelToken? _token;

  List<VehicleListItem> _vehicles = <VehicleListItem>[];
  bool _loading = false;
  bool _errorShown = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadVehicles();
  }

  @override
  void dispose() {
    _token?.cancel('User vehicles screen disposed');
    _searchController.dispose();
    super.dispose();
  }

  UserVehiclesRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= UserVehiclesRepository(api: _apiClient!);
    return _repo!;
  }

  bool _isCancelled(Object error) {
    return error is ApiException &&
        error.message.toLowerCase() == 'request cancelled';
  }

  Future<void> _loadVehicles() async {
    _token?.cancel('Reload user vehicles');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    final result = await _repoOrCreate().getVehicles(
      limit: 100,
      cancelToken: token,
    );
    if (!mounted || token.isCancelled) return;

    result.when(
      success: (items) {
        setState(() {
          _vehicles = items;
          _loading = false;
          _errorShown = false;
        });
      },
      failure: (error) {
        setState(() => _loading = false);
        if (_isCancelled(error) || _errorShown) return;
        _errorShown = true;
        final msg = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't load vehicles.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  String _safe(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? '-' : trimmed;
  }

  DateTime? _tryParse(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '-') return null;
    return DateTime.tryParse(trimmed)?.toLocal();
  }

  String _formatDate(String value) {
    final parsed = _tryParse(value);
    if (parsed == null) return _safe(value);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${parsed.year}-${two(parsed.month)}-${two(parsed.day)} ${two(parsed.hour)}:${two(parsed.minute)}';
  }

  String _statusFor(VehicleListItem item) {
    final raw = item.status.trim().toLowerCase();
    if (raw.contains('expired')) return 'Expired';
    if (raw.contains('suspend') ||
        raw.contains('inactive') ||
        raw.contains('disabled')) {
      return 'Suspended';
    }

    final expiry =
        _tryParse(item.primaryExpiry) ?? _tryParse(item.secondaryExpiry);
    if (expiry != null && expiry.isBefore(DateTime.now())) {
      return 'Expired';
    }

    if (raw.contains('active') || raw.contains('enable')) return 'Active';
    if (item.isActive) return 'Active';
    return 'Suspended';
  }

  Color _statusColor(ColorScheme colorScheme, String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.red;
      case 'suspended':
        return Colors.orange;
      default:
        return colorScheme.onSurface.withOpacity(0.6);
    }
  }

  Widget _buildShimmerCard(
    ColorScheme colorScheme,
    double hp,
    double spacing,
    double width,
  ) {
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
        padding: EdgeInsets.all(hp + 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: AdaptiveUtils.getAvatarSize(width),
              height: AdaptiveUtils.getAvatarSize(width),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withOpacity(0.1),
              ),
              child: Center(
                child: AppShimmer(
                  width: AdaptiveUtils.getIconSize(width),
                  height: AdaptiveUtils.getIconSize(width),
                  radius: AdaptiveUtils.getIconSize(width) / 2,
                ),
              ),
            ),
            SizedBox(width: spacing * 1.5),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppShimmer(width: 160, height: 18, radius: 8),
                  SizedBox(height: 8),
                  AppShimmer(width: 140, height: 14, radius: 8),
                  SizedBox(height: 8),
                  AppShimmer(width: 110, height: 14, radius: 8),
                  SizedBox(height: 8),
                  AppShimmer(width: 180, height: 14, radius: 8),
                  SizedBox(height: 8),
                  AppShimmer(width: 120, height: 14, radius: 8),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppShimmer(width: 76, height: 24, radius: 12),
                SizedBox(height: 20),
                AppShimmer(width: 100, height: 36, radius: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(ColorScheme colorScheme, double hp, double bodyFs) {
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
        padding: EdgeInsets.all(hp + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No vehicles found',
              style: GoogleFonts.inter(
                fontSize: bodyFs + 1,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask admin to assign vehicles.',
              style: GoogleFonts.inter(
                fontSize: bodyFs,
                color: colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
    );
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
    final searchQuery = _searchController.text.toLowerCase().trim();

    final filteredVehicles =
        _vehicles.where((vehicle) {
          final label = _safe(
            vehicle.plateNumber.isNotEmpty ? vehicle.plateNumber : vehicle.name,
          );
          final matchesSearch =
              searchQuery.isEmpty ||
              label.toLowerCase().contains(searchQuery) ||
              vehicle.imei.toLowerCase().contains(searchQuery);

          final status = _statusFor(vehicle);
          final matchesTab =
              selectedTab == 'All' ||
              status.toLowerCase() == selectedTab.toLowerCase();

          return matchesSearch && matchesTab;
        }).toList()..sort((a, b) {
          final ad =
              _tryParse(a.updatedAt) ??
              _tryParse(a.createdAt) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bd =
              _tryParse(b.updatedAt) ??
              _tryParse(b.createdAt) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bd.compareTo(ad);
        });

    return AppLayout(
      title: 'USER',
      subtitle: 'Vehicles',
      actionIcons: const [CupertinoIcons.add],
      onActionTaps: [
        () async {
          final result = await context.push('/user/vehicles/add');
          if (result == true) {
            _loadVehicles();
          }
        },
      ],
      showLeftAvatar: false,
      leftAvatarText: 'VH',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: hp * 3.5,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(
                  fontSize: bodyFs,
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Search vehicle no, IMEI...',
                  hintStyle: GoogleFonts.inter(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontSize: bodyFs,
                  ),
                  prefixIcon: Icon(
                    CupertinoIcons.search,
                    size: iconSize,
                    color: colorScheme.primary,
                  ),
                  border: InputBorder.none,
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
              children: ['All', 'Active', 'Expired', 'Suspended'].map((tab) {
                return SmallTab(
                  label: tab,
                  selected: selectedTab == tab,
                  onTap: () => setState(() => selectedTab = tab),
                );
              }).toList(),
            ),
            SizedBox(height: hp),
            Text(
              'Showing ${filteredVehicles.length} of ${_vehicles.length} vehicles',
              style: GoogleFonts.inter(
                fontSize: bodyFs,
                color: colorScheme.onSurface.withOpacity(0.87),
              ),
            ),
            SizedBox(height: spacing * 1.5),
            if (_loading)
              ...List.generate(
                4,
                (_) => _buildShimmerCard(colorScheme, hp, spacing, width),
              )
            else if (filteredVehicles.isEmpty)
              _buildEmptyCard(colorScheme, hp, bodyFs)
            else
              ...filteredVehicles.asMap().entries.map((entry) {
                final index = entry.key;
                final vehicle = entry.value;
                final status = _statusFor(vehicle);
                final statusColor = _statusColor(colorScheme, status);
                final vehicleLabel = _safe(
                  vehicle.plateNumber.isNotEmpty
                      ? vehicle.plateNumber
                      : vehicle.name,
                );
                final typeLabel = _safe(vehicle.type);
                final imei = _safe(vehicle.imei);
                final imeiLine = typeLabel == '-'
                    ? 'IMEI: $imei'
                    : '$typeLabel • IMEI: $imei';
                final lastData = _safe(
                  vehicle.updatedAt.isNotEmpty
                      ? _formatDate(vehicle.updatedAt)
                      : _formatDate(vehicle.createdAt),
                );

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
                        onTap: () => context.push(
                          '/user/vehicles/details/${vehicle.id}',
                          extra: vehicle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(cardPadding),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: AdaptiveUtils.getAvatarSize(width),
                                height: AdaptiveUtils.getAvatarSize(width),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.primary.withOpacity(0.1),
                                ),
                                child: Icon(
                                  CupertinoIcons.car_detailed,
                                  size: AdaptiveUtils.getIconSize(width),
                                  color: colorScheme.primary,
                                ),
                              ),
                              SizedBox(width: spacing * 1.5),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vehicleLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: bodyFs + 2,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    SizedBox(height: spacing / 2),
                                    Text(
                                      imeiLine,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: bodyFs,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    SizedBox(height: spacing / 2),
                                    Text(
                                      'Last Data: $lastData',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: bodyFs,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: spacing + 4,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      status,
                                      style: GoogleFonts.inter(
                                        fontSize: smallFs + 1,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: spacing * 2),
                                  if (status == 'Expired')
                                    OutlinedButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Payment flow TBD'),
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(100, 36),
                                        side: const BorderSide(
                                          color: Colors.red,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Pay Now',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red,
                                        ),
                                      ),
                                    )
                                  else
                                    Text(
                                      '-',
                                      style: GoogleFonts.inter(
                                        fontSize: bodyFs,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.4),
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
              }),
            SizedBox(height: hp * 3),
          ],
        ),
      ),
    );
  }
}
