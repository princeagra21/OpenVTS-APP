import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_user_list_item.dart';
import 'package:fleet_stack/core/models/admin_vehicle_details.dart';
import 'package:fleet_stack/core/models/vehicle_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_vehicles_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/admin/navigate.dart';
import 'package:fleet_stack/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:intl/intl.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  ApiClient? _apiClient;
  AdminVehiclesRepository? _repo;

  List<AdminUserListItem> _linkedUsers = const <AdminUserListItem>[];
  bool _loadingUsers = false;
  List<_VehicleLog> _logs = const <_VehicleLog>[];
  bool _loadingLogs = false;
  final TextEditingController _logsSearchController = TextEditingController();
  String _logQuery = '';
  String _logFilter = 'All';
  DateTimeRange? _logDateRange;
  bool _loadingConfig = false;
  bool _savingConfig = false;
  bool _configLoaded = false;
  CancelToken? _configToken;
  final TextEditingController _speedController =
      TextEditingController(text: '1.00');
  final TextEditingController _distanceController =
      TextEditingController(text: '1.00');
  final TextEditingController _odometerController =
      TextEditingController(text: '0');
  final TextEditingController _engineHoursController =
      TextEditingController(text: '0');
  String _ignitionSource = 'Ignition Wire';
  String _snapSpeed = '1.00';
  String _snapDistance = '1.00';
  String _snapOdometer = '0';
  String _snapEngineHours = '0';
  String _snapIgnition = 'Ignition Wire';

  String _selectedTab = 'Vehicle Details';

  final List<String> _tabs = [
    'Vehicle Details',
    'Users',
    'Logs',
    'Vehicle Config',
  ];

  AdminVehiclesRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminVehiclesRepository(api: _apiClient!);
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
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load vehicle details.")),
      );
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
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _linkedUsers = const <AdminUserListItem>[];
        _loadingUsers = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load linked users.")),
      );
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
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _logs = const <_VehicleLog>[];
        _loadingLogs = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load vehicle logs.")),
      );
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

    _speedController.text = (speed ?? 1).toStringAsFixed(2);
    _distanceController.text = (distance ?? 1).toStringAsFixed(2);
    _odometerController.text = (odo ?? 0).toStringAsFixed(0);
    _engineHoursController.text = (hours ?? 0).toStringAsFixed(0);
    _saveConfigSnapshot();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numeric values.')),
      );
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
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Saved')));
        },
        failure: (err) {
          setState(() => _savingConfig = false);
          final message =
              (err is ApiException &&
                      (err.statusCode == 401 || err.statusCode == 403))
                  ? 'Not authorized to save config.'
                  : "Couldn't save config.";
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _savingConfig = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save config.")),
      );
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

  Widget _buildVehicleDetailsTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(width);
    final spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final scale = (width / 420).clamp(0.9, 1.0);
    final fsMain = 14 * scale;
    final fsSecondary = 12 * scale;
    final fsMeta = 11 * scale;
    final cardPadding = hp + 4;

    final details = _details;
    final name = _safe(details?.nameModel);
    final plate = _safe(details?.raw['plateNumber']?.toString());
    final type = _safe(_vehicleTypeName(details));
    final imei = _safe(details?.raw['imei']?.toString());
    final sim = _safe(details?.raw['simNumber']?.toString());
    final vin = _safe(details?.vin);
    final primaryExpiry =
        _formatDateOnly(details?.raw['primaryExpiry']?.toString());
    final secondaryExpiry =
        _formatDateOnly(details?.raw['secondaryExpiry']?.toString());
    final device = details?.raw['device'];
    final speedVariation = _safe(
      device is Map ? device['speedVariation']?.toString() : null,
    );
    final distanceVariation = _safe(
      device is Map ? device['distanceVariation']?.toString() : null,
    );
    final odometer = _safe(
      device is Map ? device['odometer']?.toString() : null,
    );
    final engineHours = _safe(
      device is Map ? device['engineHours']?.toString() : null,
    );
    final deviceStatus = _safe(
      device is Map ? device['status']?.toString() : null,
    );
    final plan = details?.raw['plan'];
    final planName = _safe(plan is Map ? plan['name']?.toString() : null);
    final planPrice = _safe(plan is Map ? plan['price']?.toString() : null);
    final planCurrencyRaw =
        plan is Map ? plan['currency']?.toString() : null;
    final planCurrencyUpper = _safe(planCurrencyRaw).toUpperCase();
    final planCurrency = planCurrencyUpper == 'INR' ? 'INR' : 'INR';
    final planDuration =
        _safe(plan is Map ? plan['durationDays']?.toString() : null);
    final amountText = planPrice == '—'
        ? planCurrency
        : planCurrency == '—'
            ? planPrice
            : '$planCurrency $planPrice';

    if (_loading) {
      return _buildVehicleDetailsShimmer(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.onSurface.withOpacity(0.08)),
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
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(spacing + 2),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(25),
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
                    Row(
                      children: [
                        Container(
                          width: 40 * (fsMain / 14),
                          height: 40 * (fsMain / 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? cs.surfaceVariant
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.onSurface.withOpacity(0.12),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.directions_bus_outlined,
                            size: 18 * (fsMain / 14),
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                        ),
                        SizedBox(width: spacing * 1.5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.roboto(
                                  fontSize: fsMain,
                                  height: 20 / 14,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                              SizedBox(height: spacing * 0.4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: spacing + 4,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? cs.surfaceVariant
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  plate,
                                  style: GoogleFonts.roboto(
                                    fontSize: fsMeta,
                                    height: 14 / 11,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                              ),
                              SizedBox(height: spacing * 0.4),
                              Text(
                                type.isEmpty ? '—' : type,
                                style: GoogleFonts.roboto(
                                  fontSize: fsSecondary,
                                  height: 16 / 12,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface.withOpacity(0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final gap = spacing;
                        final cardWidth = (constraints.maxWidth - gap) / 2;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            _infoCard(
                              context,
                              width: cardWidth,
                              title: 'Device Info',
                              icon: Icons.memory,
                              lines: ['SIM: $sim', 'IMEI: $imei'],
                              lineGap: spacing * 0.6,
                              fsMeta: fsMeta,
                              fsMain: fsMain,
                            ),
                            _infoCard(
                              context,
                              width: cardWidth,
                              title: 'VIN',
                              icon: Icons.confirmation_number_outlined,
                              lines: [vin],
                              fsMeta: fsMeta,
                              fsMain: fsMain,
                            ),
                            _infoCard(
                              context,
                              width: cardWidth,
                              title: 'Primary Expiry',
                              icon: Icons.event_outlined,
                              lines: [primaryExpiry],
                              fsMeta: fsMeta,
                              fsMain: fsMain,
                            ),
                            _infoCard(
                              context,
                              width: cardWidth,
                              title: 'Secondary Expiry',
                              icon: Icons.event_outlined,
                              lines: [secondaryExpiry],
                              fsMeta: fsMeta,
                              fsMain: fsMain,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing * 2),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(spacing + 2),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(25),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Device Metrics',
                          style: AppUtils.headlineSmallBase.copyWith(
                            fontSize:
                                AdaptiveUtils.getSubtitleFontSize(width) + 2,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? cs.surfaceVariant
                                    : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            deviceStatus.isEmpty ? '—' : deviceStatus,
                            style: GoogleFonts.roboto(
                              fontSize: fsMeta,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing * 0.6),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final gap = spacing;
                        final cardWidth = (constraints.maxWidth - gap) / 2;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            _infoCard(
                              context,
                              width: cardWidth,
                              title: 'Speed Variation',
                              icon: Icons.speed,
                              lines: [speedVariation],
                              fsMeta: fsMeta,
                              fsMain: fsMain,
                            ),
                            _infoCard(
                              context,
                              width: cardWidth,
                              title: 'Distance Variation',
                              icon: Icons.route_outlined,
                              lines: [distanceVariation],
                              fsMeta: fsMeta,
                              fsMain: fsMain,
                            ),
                            _infoCard(
                              context,
                              width: cardWidth,
                              title: 'Odometer',
                              icon: Icons.av_timer_outlined,
                              lines: [odometer],
                              fsMeta: fsMeta,
                              fsMain: fsMain,
                            ),
                            _infoCard(
                              context,
                              width: cardWidth,
                              title: 'Engine Hours',
                              icon: Icons.timer_outlined,
                              lines: [engineHours],
                              fsMeta: fsMeta,
                              fsMain: fsMain,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing * 2),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(spacing + 2),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final gap = spacing;
                    final cardWidth = (constraints.maxWidth - gap) / 2;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plan Details',
                          style: AppUtils.headlineSmallBase.copyWith(
                            fontSize:
                                AdaptiveUtils.getSubtitleFontSize(width) + 2,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        SizedBox(height: spacing * 0.6),
                        Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            _infoCard(
                              context,
                              width: cardWidth,
                              title: 'Plan Name',
                              icon: Icons.workspace_premium_outlined,
                              lines: [planName],
                              fsMeta: fsMeta,
                              fsMain: fsMain,
                            ),
                            _infoCard(
                              context,
                              width: cardWidth,
                              title: 'Amount',
                              icon: Icons.payments_outlined,
                              lines: [amountText],
                              fsMeta: fsMeta,
                              fsMain: fsMain,
                            ),
                            _infoCard(
                              context,
                              width: cardWidth,
                              title: 'Duration (Days)',
                              icon: Icons.calendar_month_outlined,
                              lines: [planDuration],
                              fsMeta: fsMeta,
                              fsMain: fsMain,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleConfigTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(width);
    final scale = (width / 420).clamp(0.9, 1.0);
    final fs = 14 * scale;
    final fsSection = 18 * scale;
    final fsAction = 14 * scale;
    final fsActionIcon = 16 * scale;

    if (_loadingConfig) {
      return const AppShimmer(width: double.infinity, height: 320, radius: 12);
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vehicle Config',
                style: GoogleFonts.roboto(
                  fontSize: fsSection,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: (_savingConfig || _loadingConfig)
                        ? null
                        : () => setState(_applyConfigSnapshot),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: cs.onSurface.withOpacity(0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Icon(
                      Icons.refresh_outlined,
                      color: cs.onSurface,
                      size: fsActionIcon,
                    ),
                    label: Text(
                      'Reset',
                      style: GoogleFonts.roboto(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: fsAction,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed:
                        (_savingConfig || _loadingConfig) ? null : _saveConfig,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: SizedBox(
                      width: fsActionIcon,
                      height: fsActionIcon,
                      child: _savingConfig
                          ? AppShimmer(
                              width: fsActionIcon,
                              height: fsActionIcon,
                              radius: fsActionIcon / 2,
                            )
                          : Icon(
                              Icons.save_outlined,
                              color: cs.onPrimary,
                              size: fsActionIcon,
                            ),
                    ),
                    label: Text(
                      'Save',
                      style: GoogleFonts.roboto(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: fsAction,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildConfigSection(
            context: context,
            icon: Icons.speed,
            title: 'Speed Multiplier',
            subtitle: 'Speed ×',
            child: _numberField(controller: _speedController, unit: '×'),
            scale: scale,
          ),
          const SizedBox(height: 24),
          _buildConfigSection(
            context: context,
            icon: Icons.route_outlined,
            title: 'Distance Multiplier',
            subtitle: 'Distance ×',
            child: _numberField(controller: _distanceController, unit: '×'),
            scale: scale,
          ),
          const SizedBox(height: 24),
          _buildConfigSection(
            context: context,
            icon: Icons.av_timer_outlined,
            title: 'Set Odometer',
            subtitle: 'Odometer',
            child: _numberField(
              controller: _odometerController,
              unit: 'km',
              step: 1,
            ),
            scale: scale,
          ),
          const SizedBox(height: 24),
          _buildConfigSection(
            context: context,
            icon: Icons.timer_outlined,
            title: 'Set Engine Hours',
            subtitle: 'Engine Hours',
            child: _numberField(
              controller: _engineHoursController,
              unit: 'h',
              step: 1,
            ),
            scale: scale,
          ),
          const SizedBox(height: 24),
          _buildConfigSection(
            context: context,
            icon: Icons.power_settings_new_outlined,
            title: 'Ignition Source',
            subtitle: 'Ignition Wire / Motion-Based',
            child: _ignitionSourceBox(),
            scale: scale,
          ),
        ],
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String unit,
    double step = 0.01,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double fs = 12 * scale;

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.roboto(fontSize: fs, color: colorScheme.onSurface),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: AdaptiveUtils.isVerySmallScreen(width) ? 10 : 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        suffixText: unit,
        suffixStyle: GoogleFonts.roboto(
          fontSize: fs,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface.withOpacity(0.87),
        ),
      ),
    );
  }

  void _increment(TextEditingController controller, [double step = 0.01]) {
    double value = double.tryParse(controller.text) ?? 0;
    value += step;
    controller.text = step < 1
        ? value.toStringAsFixed(2)
        : value.toStringAsFixed(0);
    setState(() {});
  }

  void _decrement(TextEditingController controller, [double step = 0.01]) {
    double value = double.tryParse(controller.text) ?? 0;
    value -= step;
    if (value < 0) value = 0;
    controller.text = step < 1
        ? value.toStringAsFixed(2)
        : value.toStringAsFixed(0);
    setState(() {});
  }

  Widget _configBox({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required String unit,
    double step = 0.01,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double fs = AdaptiveUtils.getTitleFontSize(width);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: fs + 2,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.roboto(
              fontSize: fs - 2,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 14),
          _numberField(controller: controller, unit: unit, step: step),
        ],
      ),
    );
  }

  Widget _ignitionSourceBox() {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double chipFs = 11 * scale;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.onSurface.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _savingConfig
                  ? null
                  : () => setState(() => _ignitionSource = 'Ignition Wire'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: _ignitionSource == 'Ignition Wire'
                      ? colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.power_settings_new_outlined,
                      size: 16,
                      color: _ignitionSource == 'Ignition Wire'
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ignition Wire',
                      style: GoogleFonts.roboto(
                        fontSize: chipFs,
                        color: _ignitionSource == 'Ignition Wire'
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: _savingConfig
                  ? null
                  : () => setState(() => _ignitionSource = 'Motion-Based'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: _ignitionSource == 'Motion-Based'
                      ? colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.motion_photos_on_outlined,
                      size: 16,
                      color: _ignitionSource == 'Motion-Based'
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Motion-Based',
                      style: GoogleFonts.roboto(
                        fontSize: chipFs,
                        color: _ignitionSource == 'Motion-Based'
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? child,
    required double scale,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double titleFs = 18 * scale;
    final double subtitleFs = 12 * scale;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? colorScheme.surfaceVariant
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: colorScheme.onSurface,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.roboto(
                        fontSize: titleFs,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface.withOpacity(0.87),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.roboto(
                          fontSize: subtitleFs,
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (child != null) ...[const SizedBox(height: 12), child],
        ],
      ),
    );
  }

  Widget _buildUsersTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final cardPadding = AdaptiveUtils.getHorizontalPadding(width) + 4;
    final scale = (width / 420).clamp(0.9, 1.0);
    final fsMain = 14 * scale;
    final fsSecondary = 12 * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
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
          if (_loadingUsers)
            const AppShimmer(width: double.infinity, height: 110, radius: 16)
          else if (_linkedUsers.isEmpty)
            Text(
              'No linked users.',
              style: GoogleFonts.roboto(
                fontSize: fsSecondary,
                color: cs.onSurface.withOpacity(0.7),
              ),
            )
          else
            ..._linkedUsers.map((user) {
              final name = user.fullName.isNotEmpty ? user.fullName : '—';
              final email = user.email.isNotEmpty ? user.email : '—';
              final phone = user.fullPhone.isNotEmpty ? user.fullPhone : '—';
              final initials = user.initials;
              return Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: spacing),
                padding: EdgeInsets.all(spacing + 2),
                decoration: BoxDecoration(
                  color: cs.surface,
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
                    Container(
                      width: 40 * (fsMain / 14),
                      height: 40 * (fsMain / 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? cs.surfaceVariant
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cs.onSurface.withOpacity(0.12),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials.isNotEmpty ? initials : '--',
                        style: GoogleFonts.roboto(
                          fontSize: fsMain,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    SizedBox(width: spacing * 1.5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.roboto(
                              fontSize: fsMain,
                              height: 20 / 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          SizedBox(height: spacing * 0.4),
                          Text(
                            email,
                            style: GoogleFonts.roboto(
                              fontSize: fsSecondary,
                              height: 16 / 12,
                              color: cs.onSurface.withOpacity(0.7),
                            ),
                          ),
                          SizedBox(height: spacing * 0.4),
                          Text(
                            phone,
                            style: GoogleFonts.roboto(
                              fontSize: fsSecondary,
                              height: 16 / 12,
                              color: cs.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildLogsTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 420).clamp(0.9, 1.0);
    final headerSize = 18 * scale;
    final labelSize = AdaptiveUtils.getSubtitleFontSize(width) - 2;
    final spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final items = _filteredLogs();
    final rangeLabel = _logDateRange == null
        ? 'Date range'
        : '${DateFormat('d MMM').format(_logDateRange!.start)}'
            ' - ${DateFormat('d MMM').format(_logDateRange!.end)}';

    if (_loadingLogs) {
      return const AppShimmer(
        width: double.infinity,
        height: 320,
        radius: 12,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Vehicle Logs',
                  style: GoogleFonts.roboto(
                    fontSize: headerSize,
                    height: 24 / 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              IconButton(
                onPressed: _loadingLogs ? null : _loadLogs,
                icon: Icon(
                  Icons.refresh,
                  size: 18,
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _logsSearchController,
            onChanged: (v) => setState(() => _logQuery = v),
            decoration: InputDecoration(
              hintText: 'Search logs...',
              hintStyle: GoogleFonts.roboto(
                fontSize: labelSize,
                color: cs.onSurface.withOpacity(0.5),
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: cs.onSurface.withOpacity(0.12),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: cs.onSurface.withOpacity(0.12),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: cs.primary,
                  width: 1.5,
                ),
              ),
            ),
            style: GoogleFonts.roboto(
              fontSize: labelSize,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (_logFilter == value) return;
                    setState(() => _logFilter = value);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'All', child: Text('All')),
                    PopupMenuItem(value: 'EVENT', child: Text('Event')),
                    PopupMenuItem(value: 'POSITION', child: Text('Position')),
                    PopupMenuItem(value: 'ALARM', child: Text('Alarm')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: cs.onSurface.withOpacity(0.12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.tune,
                          size: 16,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _logFilter,
                          style: GoogleFonts.roboto(
                            fontSize: labelSize,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final now = DateTime.now();
                    DateTime? start = _logDateRange?.start;
                    DateTime? end = _logDateRange?.end;
                    final picked = await showDialog<DateTimeRange>(
                      context: context,
                      builder: (ctx) {
                        var selection = <DateTime?>[start, end];
                        return Dialog(
                          insetPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 24,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: StatefulBuilder(
                              builder: (context, setDialogState) {
                                return CalendarDatePicker2(
                                  config: CalendarDatePicker2Config(
                                    calendarType:
                                        CalendarDatePicker2Type.range,
                                    currentDate: now,
                                    selectedDayHighlightColor: cs.primary,
                                    firstDate: DateTime(2020, 1, 1),
                                    lastDate: DateTime(2035, 12, 31),
                                  ),
                                  value: selection,
                                  onValueChanged: (values) {
                                    setDialogState(() {
                                      selection = values;
                                    });
                                    if (values.length >= 2 &&
                                        values[0] != null &&
                                        values[1] != null) {
                                      Navigator.of(ctx).pop(
                                        DateTimeRange(
                                          start: values[0]!,
                                          end: values[1]!,
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                    if (picked == null) return;
                    setState(() => _logDateRange = picked);
                    _loadLogs();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: cs.onSurface.withOpacity(0.12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.date_range,
                          size: 16,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            rangeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              fontSize: labelSize,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.onSurface.withOpacity(0.08),
              ),
            ),
            child: items.isEmpty
                ? Text(
                    'No logs found.',
                    style: GoogleFonts.roboto(
                      fontSize: labelSize,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface.withOpacity(0.7),
                    ),
                  )
                : Column(
                    children: items.map((log) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.onSurface.withOpacity(0.08),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness ==
                                            Brightness.light
                                        ? Colors.grey.shade50
                                        : cs.surfaceVariant,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    _iconForPacketType(log.packetType),
                                    size: 18,
                                    color: cs.onSurface.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Event type: ${log.packetType.isNotEmpty ? log.packetType : '—'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.roboto(
                                          fontSize: headerSize - 1,
                                          fontWeight: FontWeight.w700,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.light
                                              ? Colors.grey.shade50
                                              : cs.surfaceVariant,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          'Event time: ${_formatDateTime(log.deviceTime)}',
                                          style: GoogleFonts.roboto(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _infoCell(
                                    label: 'Latitude',
                                    value: log.latitude,
                                    colorScheme: cs,
                                    labelSize: labelSize,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _infoCell(
                                    label: 'Longitude',
                                    value: log.longitude,
                                    colorScheme: cs,
                                    labelSize: labelSize,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _infoCell(
                                    label: 'Ignition',
                                    value: log.ignition,
                                    colorScheme: cs,
                                    labelSize: labelSize,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _infoCell(
                                    label: 'ACC / Valid',
                                    value: '${log.acc} / ${log.valid}',
                                    colorScheme: cs,
                                    labelSize: labelSize,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  List<_VehicleLog> _filteredLogs() {
    var items = _logs;
    if (_logFilter != 'All') {
      items = items
          .where((l) => l.packetType.toUpperCase() == _logFilter)
          .toList();
    }
    final q = _logQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items.where((l) {
        return l.packetType.toLowerCase().contains(q) ||
            l.imei.toLowerCase().contains(q) ||
            l.id.toLowerCase().contains(q);
      }).toList();
    }
    return items;
  }

  IconData _iconForPacketType(String packetType) {
    final v = packetType.toLowerCase();
    if (v.contains('event')) return Icons.flash_on;
    if (v.contains('position')) return Icons.location_on_outlined;
    if (v.contains('alarm')) return Icons.warning_amber_rounded;
    return Icons.insights_outlined;
  }

  String _formatDateTime(String raw) {
    if (raw.isEmpty || raw == '—') return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('d MMM y, h:mm a').format(dt.toLocal());
  }

  Widget _infoCell({
    required String label,
    required String value,
    required ColorScheme colorScheme,
    required double labelSize,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '—' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDetailsShimmer(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(width);
    final spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final scale = (width / 420).clamp(0.9, 1.0);
    final fsMain = 14 * scale;
    final cardPadding = hp + 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppShimmer(
          width: double.infinity,
          height: fsMain * 6.8,
          radius: 16,
        ),
        SizedBox(height: spacing),
        LayoutBuilder(
          builder: (context, constraints) {
            final gap = spacing;
            final cardWidth = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: List.generate(
                4,
                (_) => AppShimmer(
                  width: cardWidth,
                  height: fsMain * 4.8,
                  radius: 12,
                ),
              ),
            );
          },
        ),
        SizedBox(height: spacing),
        LayoutBuilder(
          builder: (context, constraints) {
            final gap = spacing;
            final cardWidth = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: List.generate(
                4,
                (_) => AppShimmer(
                  width: cardWidth,
                  height: fsMain * 4.8,
                  radius: 12,
                ),
              ),
            );
          },
        ),
        SizedBox(height: cardPadding),
      ],
    );
  }

  Widget _infoCard(
    BuildContext context, {
    required double width,
    required String title,
    required IconData icon,
    required List<String> lines,
    required double fsMeta,
    required double fsMain,
    double lineGap = 2,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(
        horizontal: fsMain * 0.9,
        vertical: fsMain * 0.6,
      ),
      constraints: const BoxConstraints(minHeight: 90),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: fsMeta + 2,
                color: cs.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: fsMeta,
                  height: 14 / 11,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          SizedBox(height: fsMain * 0.6),
          ...List.generate(lines.length, (index) {
            final line = lines[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: fsMain,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                if (index != lines.length - 1)
                  SizedBox(height: lineGap),
              ],
            );
          }),
        ],
      ),
    );
  }

  String _vehicleTypeName(AdminVehicleDetails? details) {
    if (details == null) return '';
    final raw = details.raw['vehicleType'];
    if (raw is Map && raw['name'] != null) {
      return raw['name'].toString();
    }
    return details.raw['vehicleTypeName']?.toString() ?? '';
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

  String _safe(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return '—';
    if (trimmed.toLowerCase() == 'null') return '—';
    return trimmed;
  }
}

class _VehicleLog {
  final String id;
  final String imei;
  final String packetType;
  final String deviceTime;
  final String latitude;
  final String longitude;
  final String ignition;
  final String acc;
  final String valid;

  const _VehicleLog({
    required this.id,
    required this.imei,
    required this.packetType,
    required this.deviceTime,
    required this.latitude,
    required this.longitude,
    required this.ignition,
    required this.acc,
    required this.valid,
  });

  factory _VehicleLog.fromMap(Map<String, dynamic> map) {
    String s(dynamic v) => v == null ? '' : v.toString();
    String b(dynamic v) {
      if (v == null) return '';
      if (v is bool) return v ? 'Yes' : 'No';
      return v.toString();
    }

    return _VehicleLog(
      id: s(map['id']),
      imei: s(map['imei']),
      packetType: s(map['packetType']),
      deviceTime: s(map['deviceTime']),
      latitude: s(map['latitude']),
      longitude: s(map['longitude']),
      ignition: b(map['ignition']),
      acc: b(map['acc']),
      valid: b(map['valid']),
    );
  }
}
