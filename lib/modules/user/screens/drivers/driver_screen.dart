import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_driver_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_drivers_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/user/layout/app_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  // FleetStack-API-Reference.md + Postman confirmed:
  // - GET /user/drivers
  // - GET /user/drivers/:id
  // - PATCH /user/drivers/:id
  // - DELETE /user/drivers/:id
  // - POST /user/drivers/:id/assign-vehicle
  // - POST /user/drivers/:id/unassign-vehicle
  //
  // This slice wires only the list screen to GET /user/drivers.
  String selectedTab = 'All';
  final TextEditingController _searchController = TextEditingController();

  ApiClient? _apiClient;
  UserDriversRepository? _repo;
  CancelToken? _token;

  List<AdminDriverListItem> _drivers = <AdminDriverListItem>[];
  bool _loading = false;
  bool _errorShown = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadDrivers();
  }

  @override
  void dispose() {
    _token?.cancel('User drivers screen disposed');
    _searchController.dispose();
    super.dispose();
  }

  UserDriversRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= UserDriversRepository(api: _apiClient!);
    return _repo!;
  }

  bool _isCancelled(Object error) {
    return error is ApiException &&
        error.message.toLowerCase() == 'request cancelled';
  }

  String _safe(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? '-' : trimmed;
  }

  Future<void> _loadDrivers() async {
    _token?.cancel('Reload user drivers');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    final result = await _repoOrCreate().getDrivers(cancelToken: token);
    if (!mounted || token.isCancelled) return;

    result.when(
      success: (items) {
        setState(() {
          _drivers = items;
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
            : "Couldn't load drivers.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  Future<void> _makePhoneCall(String rawPhone) async {
    final phone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.trim().isEmpty || phone == '-') return;

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

  Color _statusColor(String status) {
    return status.toLowerCase() == 'active' ? Colors.green : Colors.red;
  }

  Widget _buildShimmerCard(
    ColorScheme colorScheme,
    double width,
    double hp,
    double spacing,
    double iconSize,
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
            CircleAvatar(
              radius: AdaptiveUtils.getAvatarSize(width) / 2,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              child: AppShimmer(
                width: AdaptiveUtils.getFsAvatarFontSize(width) * 1.4,
                height: AdaptiveUtils.getFsAvatarFontSize(width) * 1.4,
                radius: AdaptiveUtils.getFsAvatarFontSize(width) * 0.7,
              ),
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
                          width: double.infinity,
                          height: 18,
                          radius: 8,
                        ),
                      ),
                      SizedBox(width: 12),
                      AppShimmer(width: 68, height: 24, radius: 12),
                    ],
                  ),
                  SizedBox(height: 12),
                  AppShimmer(width: double.infinity, height: 14, radius: 8),
                  SizedBox(height: 8),
                  AppShimmer(width: 220, height: 14, radius: 8),
                  SizedBox(height: 8),
                  AppShimmer(width: 180, height: 14, radius: 8),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AppShimmer(width: 36, height: 36, radius: 18),
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
              'No drivers found',
              style: GoogleFonts.inter(
                fontSize: bodyFs + 1,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a driver to get started.',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchQuery = _searchController.text.toLowerCase().trim();

    final filteredDrivers = _drivers.where((driver) {
      final matchesSearch =
          searchQuery.isEmpty ||
          driver.fullName.toLowerCase().contains(searchQuery) ||
          driver.fullPhone.toLowerCase().contains(searchQuery) ||
          driver.driverVehicleLabel.toLowerCase().contains(searchQuery) ||
          driver.addressLocation.toLowerCase().contains(searchQuery) ||
          driver.email.toLowerCase().contains(searchQuery);

      final matchesTab =
          selectedTab == 'All' ||
          driver.statusLabel.toLowerCase() == selectedTab.toLowerCase();

      return matchesSearch && matchesTab;
    }).toList()..sort((a, b) => a.fullName.compareTo(b.fullName));

    return AppLayout(
      title: 'USER',
      subtitle: 'Drivers Management',
      actionIcons: const [CupertinoIcons.add],
      onActionTaps: [
        () async {
          final result = await context.push('/user/drivers/add');
          if (result == true) {
            _loadDrivers();
          }
        },
      ],
      showLeftAvatar: false,
      leftAvatarText: 'DR',
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
                  hintText: 'Search name, mobile, vehicle, address...',
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
              children: ['All', 'Active', 'Inactive'].map((tab) {
                return SmallTab(
                  label: tab,
                  selected: selectedTab == tab,
                  onTap: () => setState(() => selectedTab = tab),
                );
              }).toList(),
            ),
            SizedBox(height: hp),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${filteredDrivers.length} of ${_drivers.length} drivers',
                  style: GoogleFonts.inter(
                    fontSize: bodyFs,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final result = await context.push('/user/drivers/add');
                    if (result == true) {
                      _loadDrivers();
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: hp * 1.5,
                      vertical: spacing,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      'Add Driver',
                      style: GoogleFonts.inter(
                        fontSize: bodyFs,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 1.5),
            if (_loading)
              ...List.generate(
                4,
                (_) => _buildShimmerCard(
                  colorScheme,
                  width,
                  hp,
                  spacing,
                  iconSize,
                ),
              )
            else if (filteredDrivers.isEmpty)
              _buildEmptyCard(colorScheme, hp, bodyFs)
            else
              ...filteredDrivers.asMap().entries.map((entry) {
                final index = entry.key;
                final driver = entry.value;
                final statusColor = _statusColor(driver.statusLabel);
                final phone = _safe(driver.fullPhone);
                final address = _safe(driver.addressLocation);
                final vehicle = _safe(driver.driverVehicleLabel);

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
                          '/user/drivers/details/${driver.id}',
                          extra: driver,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(cardPadding),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: AdaptiveUtils.getAvatarSize(width) / 2,
                                backgroundColor: colorScheme.primary,
                                child: Text(
                                  driver.initials,
                                  style: GoogleFonts.inter(
                                    fontSize: AdaptiveUtils.getFsAvatarFontSize(
                                      width,
                                    ),
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                              SizedBox(width: spacing * 1.5),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _safe(driver.fullName),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontSize: bodyFs + 2,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: spacing + 4,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Text(
                                            driver.statusLabel,
                                            style: GoogleFonts.inter(
                                              fontSize: smallFs + 1,
                                              fontWeight: FontWeight.w600,
                                              color: statusColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: spacing),
                                    Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.phone,
                                          size: iconSize,
                                          color: colorScheme.primary
                                              .withOpacity(0.87),
                                        ),
                                        SizedBox(width: spacing),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () => _makePhoneCall(phone),
                                            child: Text(
                                              phone,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize: bodyFs,
                                                color: colorScheme.primary,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.call,
                                            size: iconSize,
                                            color: isDark
                                                ? colorScheme.primary
                                                : Colors.green,
                                          ),
                                          onPressed: () =>
                                              _makePhoneCall(phone),
                                        ),
                                      ],
                                    ),
                                    if (vehicle != '-') ...[
                                      SizedBox(height: spacing / 2),
                                      Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.car_detailed,
                                            size: iconSize,
                                            color: colorScheme.primary
                                                .withOpacity(0.87),
                                          ),
                                          SizedBox(width: spacing),
                                          Expanded(
                                            child: Text(
                                              vehicle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize: bodyFs,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          CupertinoIcons.location,
                                          size: iconSize,
                                          color: colorScheme.primary
                                              .withOpacity(0.87),
                                        ),
                                        SizedBox(width: spacing),
                                        Expanded(
                                          child: Text(
                                            address,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontSize: bodyFs,
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
