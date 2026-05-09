import 'package:dio/dio.dart';
import 'package:open_vts/app/app_container.dart';
import 'package:open_vts/core/models/admin_user_list_item.dart';
import 'package:open_vts/core/models/admin_vehicle_details.dart';
import 'package:open_vts/core/models/vehicle_config.dart';
import 'package:open_vts/core/network/api_exception.dart';
import 'package:open_vts/core/repositories/admin_vehicles_repository.dart';
import 'package:open_vts/core/widgets/app_shimmer.dart';
import 'package:open_vts/design_system/components/open_vts_feedback.dart';
import 'package:open_vts/modules/admin/components/admin/navigate.dart';
import 'package:open_vts/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:intl/intl.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/design_system/theme/open_vts_theme.dart';

part 'vehicle_details_tab.dart';
part 'vehicle_details_config_tab.dart';
part 'vehicle_details_activity_tabs.dart';
part 'vehicle_details_helpers.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final String vehicleId;

  const VehicleDetailsScreen({super.key, required this.vehicleId});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  AdminVehicleDetails? _details;
  bool _loading = false;
  bool _errorShown = false;
  CancelToken? _token;
  CancelToken? _usersToken;
  CancelToken? _logsToken;

  AdminVehiclesRepository? _repo;

  List<AdminUserListItem> _linkedUsers = const <AdminUserListItem>[];
  bool _loadingUsers = false;
  List<_VehicleLog> _logs = const <_VehicleLog>[];
  bool _loadingLogs = false;
  final TextEditingController _logsSearchController = TextEditingController();
  String _logQuery = '';
  String _logFilter = 'All';
  DateTimeRange? _logDateRange;
  final bool _loadingConfig = false;
  bool _savingConfig = false;
  bool _configLoaded = false;
  CancelToken? _configToken;
  final TextEditingController _speedController = TextEditingController(
    text: '10000',
  );
  final TextEditingController _distanceController = TextEditingController(
    text: '100',
  );
  final TextEditingController _odometerController = TextEditingController(
    text: '10000',
  );
  final TextEditingController _engineHoursController = TextEditingController(
    text: '100000',
  );
  String _ignitionSource = 'Motion-Based';
  String _snapSpeed = '10000';
  String _snapDistance = '100';
  String _snapOdometer = '10000';
  String _snapEngineHours = '100000';
  String _snapIgnition = 'Motion-Based';

  String _selectedTab = 'Vehicle Details';

  final List<String> _tabs = [
    'Vehicle Details',
    'Users',
    'Logs',
    'Vehicle Config',
  ];

  AdminVehiclesRepository _repoOrCreate() {
    _repo ??= AppContainer.instance.adminVehiclesRepository;
    return _repo!;
  }

  @override
  void initState() {
    super.initState();
    _loadDetails();
    _loadLinkedUsers();
  }

  @override
  void dispose() {
    _token?.cancel('Vehicle details disposed');
    _usersToken?.cancel('Vehicle linked users disposed');
    _logsToken?.cancel('Vehicle logs disposed');
    _logsSearchController.dispose();
    _configToken?.cancel('Vehicle config disposed');
    _speedController.dispose();
    _distanceController.dispose();
    _odometerController.dispose();
    _engineHoursController.dispose();
    super.dispose();
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  Future<void> _loadDetails() async {
    _token?.cancel('Reload vehicle details');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final result = await _repoOrCreate().getVehicleDetails(
        widget.vehicleId,
        cancelToken: token,
      );
      if (!mounted) return;

      result.when(
        success: (details) {
          if (!mounted) return;
          setState(() {
            _details = details;
            _loading = false;
            _errorShown = false;
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() {
            _details = null;
            _loading = false;
          });

          if (_isCancelled(err)) return;

          if (_errorShown) return;
          _errorShown = true;
          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load vehicle details.'
              : "Couldn't load vehicle details.";
          OpenVtsFeedback.error(context, message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _details = null;
        _loading = false;
      });

      if (_errorShown) return;
      _errorShown = true;
      OpenVtsFeedback.error(context, "Couldn't load vehicle details.");
    }
  }

  Future<void> _loadLinkedUsers() async {
    _usersToken?.cancel('Reload linked users');
    final token = CancelToken();
    _usersToken = token;

    if (!mounted) return;
    setState(() => _loadingUsers = true);

    try {
      final res = await _repoOrCreate().getLinkedUsers(
        widget.vehicleId,
        cancelToken: token,
      );
      if (!mounted) return;
      res.when(
        success: (items) {
          setState(() {
            _linkedUsers = items;
            _loadingUsers = false;
          });
        },
        failure: (err) {
          setState(() {
            _linkedUsers = const <AdminUserListItem>[];
            _loadingUsers = false;
          });
          if (_isCancelled(err)) return;
          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load linked users.'
              : "Couldn't load linked users.";
          OpenVtsFeedback.error(context, message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _linkedUsers = const <AdminUserListItem>[];
        _loadingUsers = false;
      });
      OpenVtsFeedback.error(context, "Couldn't load linked users.");
    }
  }

  Future<void> _loadLogs() async {
    _logsToken?.cancel('Reload vehicle logs');
    final token = CancelToken();
    _logsToken = token;

    final imei = _safe(_details?.raw['imei']?.toString());
    if (imei == '—') return;

    if (!mounted) return;
    setState(() => _loadingLogs = true);

    final now = DateTime.now();
    final start = _logDateRange?.start ?? DateTime(now.year - 1, 1, 1);
    final end = _logDateRange?.end ?? now;

    final query = <String, dynamic>{
      'from': DateFormat('yyyy-MM-dd').format(start),
      'to': DateFormat('yyyy-MM-dd').format(end),
      'limit': 50,
    };

    try {
      final res = await _repoOrCreate().getVehicleLogsByImei(
        imei,
        query: query,
        cancelToken: token,
      );
      if (!mounted) return;
      res.when(
        success: (items) {
          setState(() {
            _logs = items
                .map((e) => _VehicleLog.fromMap(e))
                .toList(growable: false);
            _loadingLogs = false;
          });
        },
        failure: (err) {
          setState(() {
            _logs = const <_VehicleLog>[];
            _loadingLogs = false;
          });
          if (_isCancelled(err)) return;
          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load vehicle logs.'
              : "Couldn't load vehicle logs.";
          OpenVtsFeedback.error(context, message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _logs = const <_VehicleLog>[];
        _loadingLogs = false;
      });
      OpenVtsFeedback.error(context, "Couldn't load vehicle logs.");
    }
  }

  void _applyConfigSnapshot() {
    _speedController.text = _snapSpeed;
    _distanceController.text = _snapDistance;
    _odometerController.text = _snapOdometer;
    _engineHoursController.text = _snapEngineHours;
    _ignitionSource = _snapIgnition;
  }

  void _saveConfigSnapshot() {
    _snapSpeed = _speedController.text.trim().isNotEmpty
        ? _speedController.text.trim()
        : _snapSpeed;
    _snapDistance = _distanceController.text.trim().isNotEmpty
        ? _distanceController.text.trim()
        : _snapDistance;
    _snapOdometer = _odometerController.text.trim().isNotEmpty
        ? _odometerController.text.trim()
        : _snapOdometer;
    _snapEngineHours = _engineHoursController.text.trim().isNotEmpty
        ? _engineHoursController.text.trim()
        : _snapEngineHours;
    _snapIgnition = _ignitionSource;
  }

  void _hydrateConfigFromRaw(Map<String, dynamic> raw) {
    double? toDouble(Object? v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    final config = raw['config'] is Map
        ? Map<String, dynamic>.from((raw['config'] as Map).cast())
        : raw['vehicleConfig'] is Map
        ? Map<String, dynamic>.from((raw['vehicleConfig'] as Map).cast())
        : raw['settings'] is Map
        ? Map<String, dynamic>.from((raw['settings'] as Map).cast())
        : raw;

    final speed = toDouble(
      config['speedMultiplier'] ??
          config['speed_multiplier'] ??
          config['speedLimit'],
    );
    final distance = toDouble(
      config['distanceMultiplier'] ??
          config['distance_multiplier'] ??
          config['fuelCapacity'],
    );
    final odo = toDouble(config['odometer'] ?? config['odometerKm']);
    final hours = toDouble(config['engineHours'] ?? config['runtimeHours']);

    _speedController.text = _formatValue(speed ?? 1);
    _distanceController.text = _formatValue(distance ?? 1);
    _odometerController.text = _formatValue(odo ?? 0);
    _engineHoursController.text = _formatValue(hours ?? 0);
    _saveConfigSnapshot();
  }

  String _formatValue(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  Future<void> _loadConfig() async {
    // GET not supported yet; keep defaults and mark as loaded.
    if (_configLoaded) return;
    setState(() => _configLoaded = true);
  }

  Future<void> _saveConfig() async {
    final speed = double.tryParse(_speedController.text.trim());
    final distance = double.tryParse(_distanceController.text.trim());
    final odometer = double.tryParse(_odometerController.text.trim());
    final engineHours = double.tryParse(_engineHoursController.text.trim());

    if (speed == null ||
        distance == null ||
        odometer == null ||
        engineHours == null) {
      OpenVtsFeedback.warning(context, 'Please enter valid numeric values.');
      return;
    }

    _configToken?.cancel('Save vehicle config');
    final token = CancelToken();
    _configToken = token;

    if (!mounted) return;
    setState(() => _savingConfig = true);

    try {
      final payload = VehicleConfigUpdate(
        speedMultiplier: speed,
        distanceMultiplier: distance,
        odometer: odometer,
        engineHours: engineHours,
        ignitionSource: _ignitionSource,
      );

      final res = await _repoOrCreate().updateVehicleConfig(
        widget.vehicleId,
        payload,
        cancelToken: token,
      );
      if (!mounted) return;
      res.when(
        success: (_) {
          setState(() {
            _savingConfig = false;
            _saveConfigSnapshot();
          });
          OpenVtsFeedback.success(context, 'Saved');
        },
        failure: (err) {
          setState(() => _savingConfig = false);
          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to save config.'
              : "Couldn't save config.";
          OpenVtsFeedback.error(context, message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _savingConfig = false);
      OpenVtsFeedback.error(context, "Couldn't save config.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    final horizontalPadding = AdaptiveUtils.isVerySmallScreen(width)
        ? 8.0
        : AdaptiveUtils.isSmallScreen(width)
        ? 10.0
        : 12.0;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? OpenVtsColors.panelDark
          : OpenVtsColors.panelLight,
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
                  title: 'Vehicle screens',
                  subtitle: 'Switch between vehicle sections below.',
                  onTabSelected: (tab) {
                    setState(() => _selectedTab = tab);
                    if (tab == 'Users' && !_loadingUsers) {
                      _loadLinkedUsers();
                    }
                    if (tab == 'Logs' && !_loadingLogs) {
                      _loadLogs();
                    }
                    if (tab == 'Vehicle Config' && !_configLoaded) {
                      _loadConfig();
                    }
                  },
                ),
                const SizedBox(height: 16),
                _selectedTab == 'Vehicle Details'
                    ? _buildVehicleDetailsTab(context)
                    : _selectedTab == 'Users'
                    ? _buildUsersTab(context)
                    : _selectedTab == 'Logs'
                    ? _buildLogsTab(context)
                    : _selectedTab == 'Vehicle Config'
                    ? _buildVehicleConfigTab(context)
                    : const SizedBox.shrink(),
              ],
            ),
          ),
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            top: 0,
            child: AdminHomeAppBar(
              title: 'Vehicle Details',
              leadingIcon: Icons.directions_car,
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
}
