import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_driver_list_item.dart';
import 'package:fleet_stack/core/models/admin_user_details.dart';
import 'package:fleet_stack/core/models/admin_vehicle_list_item.dart';
import 'package:fleet_stack/core/models/admin_transaction_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_users_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:fleet_stack/modules/admin/components/admin/navigate.dart';
import 'package:fleet_stack/modules/admin/screens/account/widget/admin_user_activity_tab.dart';
import 'package:fleet_stack/modules/admin/screens/account/widget/admin_user_details_ui.dart';
import 'package:fleet_stack/modules/admin/screens/account/widget/admin_user_documents_tab.dart';
import 'package:fleet_stack/modules/admin/screens/account/widget/admin_user_drivers_tab.dart';
import 'package:fleet_stack/modules/admin/screens/account/widget/admin_user_payments_tab.dart';
import 'package:fleet_stack/modules/admin/screens/account/widget/admin_user_profile_tab.dart';
import 'package:fleet_stack/modules/admin/screens/account/widget/admin_user_tickets_tab.dart';
import 'package:fleet_stack/modules/admin/screens/account/widget/admin_user_vehicles_tab.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class UserDetailsScreen extends StatefulWidget {
  final String id;
  final String? name;

  const UserDetailsScreen({
    super.key,
    required this.id,
    this.name,
  });

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  AdminUserDetails? _details;
  bool _loadingDetails = false;
  CancelToken? _detailsToken;

  List<AdminVehicleListItem> _vehicles = const <AdminVehicleListItem>[];
  bool _loadingVehicles = false;
  bool _vehiclesLoaded = false;
  CancelToken? _vehiclesToken;

  List<AdminDriverListItem> _drivers = const <AdminDriverListItem>[];
  bool _loadingDrivers = false;
  bool _driversLoaded = false;
  CancelToken? _driversToken;

  List<AdminTransactionItem> _payments = const <AdminTransactionItem>[];
  bool _loadingPayments = false;
  bool _paymentsLoaded = false;
  CancelToken? _paymentsToken;

  String _selectedTab = 'Profile';

  final List<String> _tabs = const [
    'Profile',
    'Vehicles',
    'Drivers',
    'Documents',
    'Tickets',
    'Payments',
    'Activity Logs',
  ];

  final Map<String, bool> _tabErrorShown = {};
  int _detailReloadNonce = 0;

  ApiClient? _api;
  AdminUsersRepository? _repo;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _detailsToken?.cancel('User details disposed');
    _vehiclesToken?.cancel('Vehicles tab disposed');
    _driversToken?.cancel('Drivers tab disposed');
    _paymentsToken?.cancel('Payments tab disposed');
    super.dispose();
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  void _showTabErrorOnce(String tab, String message) {
    if (_tabErrorShown[tab] == true || !mounted) return;

    _tabErrorShown[tab] = true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  AdminUsersRepository _repoOrCreate() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );

    _repo ??= AdminUsersRepository(api: _api!);

    return _repo!;
  }

  Future<void> _loadDetails({bool silent = false}) async {
    _detailsToken?.cancel('Reload user details');

    final token = CancelToken();
    _detailsToken = token;

    if (!mounted) return;
    if (!silent) setState(() => _loadingDetails = true);

    try {
      final result = await _repoOrCreate().getUserDetails(
        widget.id,
        cancelToken: token,
      );

      if (!mounted) return;

      result.when(
        success: (details) {
          setState(() {
            _details = details;
            _loadingDetails = false;
            _tabErrorShown['Profile'] = false;
          });

          _ensureSelectedTabLoaded(_selectedTab);
        },
        failure: (err) {
          setState(() {
            _loadingDetails = false;
          });

          if (_isCancelled(err)) return;

          final message = (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load user details.'
              : "Couldn't load user details.";

          _showTabErrorOnce('Profile', message);
        },
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingDetails = false;
      });

      _showTabErrorOnce('Profile', "Couldn't load user details.");
    }
  }

  Widget tabSelectionCard(
    BuildContext context, {
    required String selectedTab,
    required List<String> tabs,
    required String title,
    required String subtitle,
    required ValueChanged<String> onTabSelected,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151515) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.20 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tabs.map((tab) {
                final selected = tab == selectedTab;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () => onTabSelected(tab),
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.colorScheme.primary
                            : isDark
                                ? Colors.white.withOpacity(0.06)
                                : const Color(0xFFF4F5F7),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected
                              ? theme.colorScheme.primary
                              : isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.06),
                        ),
                      ),
                      child: Text(
                        tab,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadVehicles() async {
    _vehiclesToken?.cancel('Reload user vehicles');

    final token = CancelToken();
    _vehiclesToken = token;

    if (!mounted) return;

    setState(() => _loadingVehicles = true);

    try {
      final result = await _repoOrCreate().getUserLinkedVehicles(
        widget.id,
        cancelToken: token,
      );

      if (!mounted) return;

      result.when(
        success: (items) {
          setState(() {
            _vehicles = items;
            _vehiclesLoaded = true;
            _loadingVehicles = false;
            _tabErrorShown['Vehicles'] = false;
          });
        },
        failure: (err) {
          setState(() {
            _vehicles = const <AdminVehicleListItem>[];
            _vehiclesLoaded = true;
            _loadingVehicles = false;
          });

          if (_isCancelled(err)) return;

          final message = (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load user vehicles.'
              : "Couldn't load user vehicles.";

          _showTabErrorOnce('Vehicles', message);
        },
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _vehicles = const <AdminVehicleListItem>[];
        _vehiclesLoaded = true;
        _loadingVehicles = false;
      });

      _showTabErrorOnce('Vehicles', "Couldn't load user vehicles.");
    }
  }

  Future<void> _loadDrivers() async {
    _driversToken?.cancel('Reload user drivers');

    final token = CancelToken();
    _driversToken = token;

    if (!mounted) return;

    setState(() => _loadingDrivers = true);

    try {
      final result = await _repoOrCreate().getUserLinkedDrivers(
        widget.id,
        cancelToken: token,
      );

      if (!mounted) return;

      result.when(
        success: (items) {
          setState(() {
            _drivers = items;
            _driversLoaded = true;
            _loadingDrivers = false;
            _tabErrorShown['Drivers'] = false;
          });
        },
        failure: (err) {
          setState(() {
            _drivers = const <AdminDriverListItem>[];
            _driversLoaded = true;
            _loadingDrivers = false;
          });

          if (_isCancelled(err)) return;

          final message = (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load user drivers.'
              : "Couldn't load user drivers.";

          _showTabErrorOnce('Drivers', message);
        },
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _drivers = const <AdminDriverListItem>[];
        _driversLoaded = true;
        _loadingDrivers = false;
      });

      _showTabErrorOnce('Drivers', "Couldn't load user drivers.");
    }
  }

  Future<void> _loadPayments() async {
    _paymentsToken?.cancel('Reload user payments');

    final token = CancelToken();
    _paymentsToken = token;

    if (!mounted) return;

    setState(() => _loadingPayments = true);

    try {
      final result = await _repoOrCreate().getUserPayments(
        widget.id,
        cancelToken: token,
      );

      if (!mounted) return;

      result.when(
        success: (items) {
          setState(() {
            _payments = items;
            _paymentsLoaded = true;
            _loadingPayments = false;
            _tabErrorShown['Payments'] = false;
          });
        },
        failure: (err) {
          setState(() {
            _payments = const <AdminTransactionItem>[];
            _paymentsLoaded = true;
            _loadingPayments = false;
          });

          if (_isCancelled(err)) return;

          final message = (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load user payments.'
              : "Couldn't load user payments.";

          _showTabErrorOnce('Payments', message);
        },
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _payments = const <AdminTransactionItem>[];
        _paymentsLoaded = true;
        _loadingPayments = false;
      });

      _showTabErrorOnce('Payments', "Couldn't load user payments.");
    }
  }

  void _selectTab(String tab) {
    if (_selectedTab == tab) return;

    setState(() => _selectedTab = tab);

    _ensureSelectedTabLoaded(tab);
  }

  void _ensureSelectedTabLoaded(String tab) {
    switch (tab) {
      case 'Vehicles':
        if (!_vehiclesLoaded && !_loadingVehicles) _loadVehicles();
        break;
      case 'Drivers':
        if (!_driversLoaded && !_loadingDrivers) _loadDrivers();
        break;
      case 'Payments':
        if (!_paymentsLoaded && !_loadingPayments) _loadPayments();
        break;
      case 'Documents':
      case 'Tickets':
      case 'Activity Logs':
      default:
        break;
    }
  }

  Future<void> _refreshDetails() async {
    await _loadDetails(silent: true);

    if (!mounted) return;

    switch (_selectedTab) {
      case 'Vehicles':
        _vehiclesLoaded = false;
        await _loadVehicles();
        break;
      case 'Drivers':
        _driversLoaded = false;
        await _loadDrivers();
        break;
      case 'Payments':
        _paymentsLoaded = false;
        await _loadPayments();
        break;
      case 'Documents':
      case 'Tickets':
      case 'Activity Logs':
      default:
        break;
    }

    if (mounted) setState(() => _detailReloadNonce++);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = AdaptiveUtils.getHorizontalPadding(width);
    final topPadding = MediaQuery.of(context).padding.top;
    final scale = (width / 420).clamp(0.9, 1.0);
    final bodyFs = 14 * scale;
    final smallFs = 12 * scale;

    final headerName =
        widget.name?.trim().isNotEmpty == true ? widget.name! : 'User Details';

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          Positioned.fill(
            child: RefreshIndicator(
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surface,
              onRefresh: _refreshDetails,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  topPadding + AppUtils.appBarHeightCustom + 28,
                  horizontalPadding,
                  84,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NavigateBox(
                      selectedTab: _selectedTab,
                      tabs: _tabs,
                      title: 'User mobile screens',
                      subtitle: 'Switch between the user screens below.',
                      onTabSelected: _selectTab,
                    ),
                    const SizedBox(height: 4),
                    KeyedSubtree(
                      key: ValueKey(
                        'admin_user_${_selectedTab}_$_detailReloadNonce',
                      ),
                      child: _buildTabContent(bodyFs, smallFs),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            top: 0,
            child: AdminHomeAppBar(
              title: headerName,
              leadingIcon: Symbols.group,
              onClose: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(double bodyFs, double smallFs) {
    switch (_selectedTab) {
      case 'Profile':
        return Column(
          children: [
            const SizedBox(height: 24),
            AdminUserProfileTab(
              details: _details,
              loading: _loadingDetails,
              bodyFontSize: bodyFs,
              userId: widget.id,
              onRefresh: ({bool silent = false}) {
                _loadDetails(silent: silent);
              },
            ),
            const SizedBox(height: 24),
          ],
        );
      case 'Vehicles':
        return Column(
          children: [
            const SizedBox(height: 24),
            AdminUserVehiclesTab(
              userId: widget.id,
              items: _vehicles,
              loading: _loadingVehicles,
              onAssigned: _loadVehicles,
            ),
            const SizedBox(height: 24),
          ],
        );

      case 'Drivers':
        return Column(
          children: [
            const SizedBox(height: 24),
            AdminUserDriversTab(
              items: _drivers,
              loading: _loadingDrivers,
              bodyFontSize: bodyFs,
              smallFontSize: smallFs,
            ),
            const SizedBox(height: 24),
          ],
        );

      case 'Documents':
        return Column(
          children: [
            const SizedBox(height: 24),
            AdminUserDocumentsTab(
              userId: widget.id,
            ),
            const SizedBox(height: 24),
          ],
        );

      case 'Tickets':
        return Column(
          children: [
            const SizedBox(height: 24),
            if (_details != null)
              AdminUserTicketsTab(
                userId: widget.id,
                userSummary: _details!.summary,
              )
            else if (_loadingDetails)
              listShimmer(context, count: 2, height: 100)
            else
              const Center(
                child: Text('User details not available.'),
              ),
            const SizedBox(height: 24),
          ],
        );

      case 'Payments':
        return Column(
          children: [
            const SizedBox(height: 24),
            AdminUserPaymentsTab(
              userId: widget.id,
              items: _payments,
              loading: _loadingPayments,
              bodyFontSize: bodyFs,
              smallFontSize: smallFs,
              onRenew: _loadPayments,
            ),
            const SizedBox(height: 24),
          ],
        );

      case 'Activity Logs':
        return Column(
          children: [
            const SizedBox(height: 24),
            AdminUserActivityTab(userId: widget.id),
            const SizedBox(height: 24),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
