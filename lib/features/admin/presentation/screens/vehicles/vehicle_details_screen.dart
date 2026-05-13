import 'package:open_vts/features/vehicles/domain/entities/vehicle_config.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_vehicle_details.dart';
import 'package:open_vts/features/admin/domain/entities/admin_vehicle_log_item.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_vehicle_detail_controller.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_feedback.dart';
import 'package:open_vts/features/admin/presentation/components/admin/navigate.dart';
import 'package:open_vts/features/admin/presentation/components/appbars/admin_home_appbar.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:intl/intl.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

part 'vehicle_details_tab.dart';
part 'vehicle_details_config_tab.dart';
part 'vehicle_details_activity_tabs.dart';
part 'vehicle_details_helpers.dart';

class VehicleDetailsScreen extends ConsumerStatefulWidget {
  final String vehicleId;

  const VehicleDetailsScreen({super.key, required this.vehicleId});

  @override
  ConsumerState<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends ConsumerState<VehicleDetailsScreen> {
  final TextEditingController _logsSearchController = TextEditingController();
  String _logQuery = '';
  String _logFilter = 'All';
  DateTimeRange? _logDateRange;
  bool _configLoaded = false;
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

  AdminVehicleDetailState get _vehicleState => ref.read(
        adminVehicleDetailControllerProvider(widget.vehicleId),
      );

  AdminVehicleDetailController get _vehicleController => ref.read(
        adminVehicleDetailControllerProvider(widget.vehicleId).notifier,
      );


  AdminVehicleDetails? get _details => _vehicleState.vehicle;
  List<AdminUserListItem> get _linkedUsers => _vehicleState.users;
  List<AdminVehicleLogItem> get _logs => _vehicleState.logs;
  bool get _loading => _vehicleState.isLoading;
  bool get _loadingUsers => _vehicleState.isLoadingUsers;
  bool get _loadingLogs => _vehicleState.isLoadingLogs;
  bool get _loadingConfig => false;
  bool get _savingConfig => _vehicleState.isSaving;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      _vehicleController.loadLinkedUsers();
    });
  }

  @override
  void dispose() {
    _logsSearchController.dispose();
    _speedController.dispose();
    _distanceController.dispose();
    _odometerController.dispose();
    _engineHoursController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    await _vehicleController.loadVehicle(widget.vehicleId);
  }

  Future<void> _loadLinkedUsers() async {
    await _vehicleController.loadLinkedUsers();
  }

  Future<void> _loadLogs() async {
    await _vehicleController.loadLogs(
      from: _logDateRange?.start,
      to: _logDateRange?.end,
    );
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

  Future<void> _loadConfig() async {
    // GET not supported yet; keep defaults and mark as loaded.
    if (_configLoaded) return;
    updateLocalUiState(this, () => _configLoaded = true);
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

    final payload = VehicleConfigUpdate(
      speedMultiplier: speed,
      distanceMultiplier: distance,
      odometer: odometer,
      engineHours: engineHours,
      ignitionSource: _ignitionSource,
    );

    final ok = await _vehicleController.updateConfig(payload);
    if (ok) {
      _saveConfigSnapshot();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AdminVehicleDetailState>(
      adminVehicleDetailControllerProvider(widget.vehicleId),
      (previous, next) {
        final effect = next.effect;
        if (effect == null || identical(previous?.effect, effect)) return;
        if (effect.isError) {
          OpenVtsFeedback.error(context, effect.message);
        } else {
          OpenVtsFeedback.success(context, effect.message);
        }
        ref.read(adminVehicleDetailControllerProvider(widget.vehicleId).notifier).clearEffect();
      },
    );

    ref.watch(adminVehicleDetailControllerProvider(widget.vehicleId));

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
                    updateLocalUiState(this, () => _selectedTab = tab);
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
