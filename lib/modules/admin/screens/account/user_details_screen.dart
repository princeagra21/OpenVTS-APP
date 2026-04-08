import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_document_item.dart';
import 'package:fleet_stack/core/models/admin_driver_list_item.dart';
import 'package:fleet_stack/core/models/admin_ticket_list_item.dart';
import 'package:fleet_stack/core/models/admin_transaction_item.dart';
import 'package:fleet_stack/core/models/admin_user_details.dart';
import 'package:fleet_stack/core/models/admin_vehicle_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_users_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/admin/screens/account/widget/admin_user_documents_tab.dart';
import 'package:fleet_stack/modules/admin/screens/account/widget/admin_user_drivers_tab.dart';
import 'package:fleet_stack/modules/admin/screens/account/widget/admin_user_payments_tab.dart';
import 'package:fleet_stack/modules/admin/screens/account/widget/admin_user_profile_tab.dart';
import 'package:fleet_stack/modules/admin/screens/account/widget/admin_user_tickets_tab.dart';
import 'package:fleet_stack/modules/admin/screens/account/widget/admin_user_vehicles_tab.dart';
import 'package:fleet_stack/modules/admin/components/admin/navigate.dart';
import 'package:fleet_stack/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class AdminUserDetailsScreen extends StatefulWidget {
  final String id;

  const AdminUserDetailsScreen({super.key, required this.id});

  @override
  State<AdminUserDetailsScreen> createState() => _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends State<AdminUserDetailsScreen> {
  // Confirmed endpoints (FleetStack-API-Reference.md + Postman):
  // - GET /admin/users/:id
  // - GET /admin/unlinkvehicles/:userId
  // - GET /admin/users/unlinkeddrivers/:userId
  // - GET /admin/documents/:userId
  // - GET /admin/tickets?userId=:userId
  // - GET /admin/payments?page=1&limit=1000&userId=:userId

  static const List<String> _tabs = <String>[
    'Profile',
    'Vehicles',
    'Drivers',
    'Documents',
    'Tickets',
    'Payments',
  ];

  String _selectedTab = 'Profile';

  AdminUserDetails? _details;
  bool _loadingDetails = false;
  bool _detailsErrorShown = false;
  CancelToken? _detailsToken;

  List<AdminVehicleListItem> _vehicles = const <AdminVehicleListItem>[];
  bool _loadingVehicles = false;
  bool _vehiclesLoaded = false;
  CancelToken? _vehiclesToken;

  List<AdminDriverListItem> _drivers = const <AdminDriverListItem>[];
  bool _loadingDrivers = false;
  bool _driversLoaded = false;
  CancelToken? _driversToken;

  List<AdminDocumentItem> _documents = const <AdminDocumentItem>[];
  bool _loadingDocuments = false;
  bool _documentsLoaded = false;
  CancelToken? _documentsToken;

  List<AdminTicketListItem> _tickets = const <AdminTicketListItem>[];
  bool _loadingTickets = false;
  bool _ticketsLoaded = false;
  CancelToken? _ticketsToken;

  List<AdminTransactionItem> _payments = const <AdminTransactionItem>[];
  bool _loadingPayments = false;
  bool _paymentsLoaded = false;
  CancelToken? _paymentsToken;

  final Map<String, bool> _tabErrorShown = <String, bool>{
    'Vehicles': false,
    'Drivers': false,
    'Documents': false,
    'Tickets': false,
    'Payments': false,
  };

  ApiClient? _apiClient;
  AdminUsersRepository? _repo;

  String _safe(String? value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.trim();
    return text.isEmpty ? fallback : text;
  }

  AdminUsersRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminUsersRepository(api: _apiClient!);
    return _repo!;
  }

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
    _documentsToken?.cancel('Documents tab disposed');
    _ticketsToken?.cancel('Tickets tab disposed');
    _paymentsToken?.cancel('Payments tab disposed');
    super.dispose();
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  void _showDetailsErrorOnce(String message) {
    if (_detailsErrorShown || !mounted) return;
    _detailsErrorShown = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showTabErrorOnce(String tab, String message) {
    if ((_tabErrorShown[tab] ?? false) || !mounted) return;
    _tabErrorShown[tab] = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadDetails() async {
    _detailsToken?.cancel('Reload user details');
    final token = CancelToken();
    _detailsToken = token;

    if (!mounted) return;
    setState(() => _loadingDetails = true);

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
            _detailsErrorShown = false;
          });
        },
        failure: (err) {
          setState(() {
            _details = null;
            _loadingDetails = false;
          });
          if (_isCancelled(err)) return;
          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load user details.'
              : "Couldn't load user details.";
          _showDetailsErrorOnce(message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _details = null;
        _loadingDetails = false;
      });
      _showDetailsErrorOnce("Couldn't load user details.");
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
      case 'Documents':
        if (!_documentsLoaded && !_loadingDocuments) _loadDocuments();
        break;
      case 'Tickets':
        if (!_ticketsLoaded && !_loadingTickets) _loadTickets();
        break;
      case 'Payments':
        if (!_paymentsLoaded && !_loadingPayments) _loadPayments();
        break;
      default:
        break;
    }
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
          final message =
              (err is ApiException &&
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
          final message =
              (err is ApiException &&
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

  Future<void> _loadDocuments() async {
    _documentsToken?.cancel('Reload user documents');
    final token = CancelToken();
    _documentsToken = token;

    if (!mounted) return;
    setState(() => _loadingDocuments = true);

    try {
      final result = await _repoOrCreate().getUserDocuments(
        widget.id,
        cancelToken: token,
      );
      if (!mounted) return;
      result.when(
        success: (items) {
          setState(() {
            _documents = items;
            _documentsLoaded = true;
            _loadingDocuments = false;
            _tabErrorShown['Documents'] = false;
          });
        },
        failure: (err) {
          setState(() {
            _documents = const <AdminDocumentItem>[];
            _documentsLoaded = true;
            _loadingDocuments = false;
          });
          if (_isCancelled(err)) return;
          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load user documents.'
              : "Couldn't load user documents.";
          _showTabErrorOnce('Documents', message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _documents = const <AdminDocumentItem>[];
        _documentsLoaded = true;
        _loadingDocuments = false;
      });
      _showTabErrorOnce('Documents', "Couldn't load user documents.");
    }
  }

  Future<void> _loadTickets() async {
    _ticketsToken?.cancel('Reload user tickets');
    final token = CancelToken();
    _ticketsToken = token;

    if (!mounted) return;
    setState(() => _loadingTickets = true);

    try {
      final result = await _repoOrCreate().getUserTickets(
        widget.id,
        cancelToken: token,
      );
      if (!mounted) return;
      result.when(
        success: (items) {
          setState(() {
            _tickets = items;
            _ticketsLoaded = true;
            _loadingTickets = false;
            _tabErrorShown['Tickets'] = false;
          });
        },
        failure: (err) {
          setState(() {
            _tickets = const <AdminTicketListItem>[];
            _ticketsLoaded = true;
            _loadingTickets = false;
          });
          if (_isCancelled(err)) return;
          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load user tickets.'
              : "Couldn't load user tickets.";
          _showTabErrorOnce('Tickets', message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _tickets = const <AdminTicketListItem>[];
        _ticketsLoaded = true;
        _loadingTickets = false;
      });
      _showTabErrorOnce('Tickets', "Couldn't load user tickets.");
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
          final message =
              (err is ApiException &&
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final bodyFs = AdaptiveUtils.getTitleFontSize(screenWidth) - 1;
    final smallFs = AdaptiveUtils.getTitleFontSize(screenWidth) - 3;
    final topPadding = MediaQuery.of(context).padding.top;
    final horizontalPadding = AdaptiveUtils.isVerySmallScreen(screenWidth)
        ? 8.0
        : AdaptiveUtils.isSmallScreen(screenWidth)
            ? 10.0
            : 12.0;

    final headerName = _safe(
      _details?.fullName,
      fallback: _safe(_details?.username, fallback: 'User Details'),
    );

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
                NavigateBox(
                  selectedTab: _selectedTab,
                  tabs: _tabs,
                  title: 'User mobile screens',
                  subtitle: 'Switch between the user screens below.',
                  onTabSelected: _selectTab,
                ),
                const SizedBox(height: 4),
                _buildTabContent(bodyFs, smallFs),
                const SizedBox(height: 24),
              ],
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
      case 'Vehicles':
        return Column(
          children: [
            const SizedBox(height: 24),
            AdminUserVehiclesTab(
              items: _vehicles,
              loading: _loadingVehicles,
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
              items: _documents,
              loading: _loadingDocuments,
              bodyFontSize: bodyFs,
              smallFontSize: smallFs,
            ),
            const SizedBox(height: 24),
          ],
        );
      case 'Tickets':
        return Column(
          children: [
            const SizedBox(height: 24),
            AdminUserTicketsTab(
              items: _tickets,
              loading: _loadingTickets,
              bodyFontSize: bodyFs,
              smallFontSize: smallFs,
            ),
            const SizedBox(height: 24),
          ],
        );
      case 'Payments':
        return Column(
          children: [
            const SizedBox(height: 24),
            AdminUserPaymentsTab(
              items: _payments,
              loading: _loadingPayments,
              bodyFontSize: bodyFs,
              smallFontSize: smallFs,
            ),
            const SizedBox(height: 24),
          ],
        );
      case 'Profile':
      default:
        return Column(
          children: [
            const SizedBox(height: 24),
            AdminUserProfileTab(
              details: _details,
              loading: _loadingDetails,
              bodyFontSize: bodyFs,
              userId: widget.id,
              onRefresh: _loadDetails,
            ),
            const SizedBox(height: 24),
          ],
        );
    }
  }
}
