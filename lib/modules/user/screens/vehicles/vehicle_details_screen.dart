import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/user_vehicle_details.dart';
import 'package:fleet_stack/core/models/vehicle_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_vehicles_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:fleet_stack/modules/user/components/appbars/user_home_appbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final String vehicleId;
  final VehicleListItem? initialVehicle;

  const VehicleDetailsScreen({
    super.key,
    required this.vehicleId,
    this.initialVehicle,
  });

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  // Confirmed User endpoint:
  // - GET /user/vehicles/:id
  // Key mapping handled:
  // - data.data.vehicle
  // - data.vehicle
  // - root vehicle map
  UserVehicleDetails? _details;
  bool _loading = false;
  bool _errorShown = false;
  CancelToken? _token;
  String _selectedTab = 'Vehicle Details';
  bool _loadingConfig = true;
  bool _savingConfig = false;
  bool _configLoaded = false;
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

  final List<String> _tabs = [
    'Vehicle Details',
    'Documents',
    'Config',
  ];

  ApiClient? _apiClient;
  UserVehiclesRepository? _repo;

  String _vehicleAppBarTitle() {
    final details = _details;
    final initial = widget.initialVehicle;
    final fromDetails = details?.displayTitle.trim();
    if (fromDetails != null && fromDetails.isNotEmpty) return fromDetails;
    final fromInitialName = initial?.name.trim();
    if (fromInitialName != null && fromInitialName.isNotEmpty) {
      return fromInitialName;
    }
    final fromInitialPlate = initial?.plateNumber.trim();
    if (fromInitialPlate != null && fromInitialPlate.isNotEmpty) {
      return fromInitialPlate;
    }
    return 'Vehicle Details';
  }

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _token?.cancel('User vehicle details disposed');
    _speedController.dispose();
    _distanceController.dispose();
    _odometerController.dispose();
    _engineHoursController.dispose();
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

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  Future<void> _loadDetails() async {
    _token?.cancel('Reload user vehicle details');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadingConfig = true;
    });

    final result = await _repoOrCreate().getVehicleDetails(
      widget.vehicleId,
      cancelToken: token,
    );
    if (!mounted || token.isCancelled) return;

    result.when(
      success: (details) {
        setState(() {
          _details = details;
          _loading = false;
          _errorShown = false;
          _loadingConfig = false;
        });
        _loadConfigFromDetails(details);
      },
      failure: (error) {
        setState(() => _loading = false);
        setState(() => _loadingConfig = false);
        if (_isCancelled(error) || _errorShown) return;
        _errorShown = true;
        final msg = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't load vehicle details.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  void _loadConfigFromDetails(UserVehicleDetails details) {
    final device = details.device;
    String _fmtDecimal(Object? v, {int fixed = 2}) {
      final text = _safe(v?.toString());
      final parsed = double.tryParse(text);
      if (parsed == null) return text == '—' ? '' : text;
      return parsed.toStringAsFixed(fixed);
    }

    _speedController.text =
        _fmtDecimal(device['speedVariation'], fixed: 2).isEmpty
            ? '1.00'
            : _fmtDecimal(device['speedVariation'], fixed: 2);
    _distanceController.text =
        _fmtDecimal(device['distanceVariation'], fixed: 2).isEmpty
            ? '1.00'
            : _fmtDecimal(device['distanceVariation'], fixed: 2);
    _odometerController.text =
        _fmtDecimal(device['odometer'], fixed: 0).isEmpty
            ? '0'
            : _fmtDecimal(device['odometer'], fixed: 0);
    _engineHoursController.text =
        _fmtDecimal(device['engineHours'], fixed: 0).isEmpty
            ? '0'
            : _fmtDecimal(device['engineHours'], fixed: 0);
    final ignition = _safe(device['ignitionSource']?.toString());
    if (ignition.isNotEmpty && ignition != '—') {
      _ignitionSource =
          ignition.toLowerCase().contains('motion') ? 'Motion-Based' : 'Ignition Wire';
    }

    _snapSpeed = _speedController.text;
    _snapDistance = _distanceController.text;
    _snapOdometer = _odometerController.text;
    _snapEngineHours = _engineHoursController.text;
    _snapIgnition = _ignitionSource;
    _configLoaded = true;
  }

  void _applyConfigSnapshot() {
    _speedController.text = _snapSpeed;
    _distanceController.text = _snapDistance;
    _odometerController.text = _snapOdometer;
    _engineHoursController.text = _snapEngineHours;
    _ignitionSource = _snapIgnition;
    setState(() {});
  }

  Future<void> _saveConfig() async {
    const maxMultiplier = 10.0;
    const maxOdometer = 1000000.0;
    const maxEngineHours = 100000.0;

    String? validateRange(
      String label,
      String raw, {
      required double min,
      required double max,
    }) {
      final text = raw.trim();
      if (text.isEmpty) return null;
      final value = double.tryParse(text);
      if (value == null) {
        return '$label must be a valid number.';
      }
      if (value < min || value > max) {
        return '$label must be between ${min.toStringAsFixed(min == min.toInt() ? 0 : 1)} and ${max.toStringAsFixed(max == max.toInt() ? 0 : 1)}.';
      }
      return null;
    }

    final speedError = validateRange(
      'Speed Multiplier',
      _speedController.text,
      min: 0.1,
      max: maxMultiplier,
    );
    final distanceError = validateRange(
      'Distance Multiplier',
      _distanceController.text,
      min: 0.1,
      max: maxMultiplier,
    );
    final odometerError = validateRange(
      'Odometer',
      _odometerController.text,
      min: 0,
      max: maxOdometer,
    );
    final engineHoursError = validateRange(
      'Engine Hours',
      _engineHoursController.text,
      min: 0,
      max: maxEngineHours,
    );

    final validationError =
        speedError ?? distanceError ?? odometerError ?? engineHoursError;
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _savingConfig = true);
    try {
      final speed = double.tryParse(_speedController.text.trim());
      final distance = double.tryParse(_distanceController.text.trim());
      final odometer = double.tryParse(_odometerController.text.trim());
      final engineHours = double.tryParse(_engineHoursController.text.trim());

      final payload = <String, dynamic>{
        if (speed != null) 'speedVariation': speed,
        if (distance != null) 'distanceVariation': distance,
        if (odometer != null) 'odometer': odometer,
        if (engineHours != null) 'engineHours': engineHours,
        'ignitionSource': _ignitionSource == 'Motion-Based' ? 'MOTION' : 'ACC',
      };

      final api = _repoOrCreate().api;
      final res = await api.patch(
        '/user/vehicles/${widget.vehicleId}/config',
        data: payload,
      );

      res.when(
        success: (_) {
          _snapSpeed = _speedController.text;
          _snapDistance = _distanceController.text;
          _snapOdometer = _odometerController.text;
          _snapEngineHours = _engineHoursController.text;
          _snapIgnition = _ignitionSource;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Config updated')));
        },
        failure: (err) {
          final msg = err is ApiException && err.message.trim().isNotEmpty
              ? err.message
              : "Couldn't update config.";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't update config.")));
    } finally {
      if (mounted) setState(() => _savingConfig = false);
    }
  }

  String _safe(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return '—';
    return text;
  }

  String _formatDateTime(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return '—';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final local = parsed.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year}, '
        '${two(local.hour)}:${two(local.minute)}';
  }

  String _formatAmount(double? amount, String currency) {
    if (amount == null) return '—';
    final symbol = currency.toUpperCase() == 'INR' ? '₹' : '$currency ';
    final rounded = amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);
    return '$symbol$rounded';
  }

  String _headerTitle() {
    final details = _details;
    if (details != null) return _safe(details.displayTitle);
    final initial = widget.initialVehicle;
    if (initial == null) return '—';
    final plate = initial.plateNumber.trim();
    if (plate.isNotEmpty) return plate;
    final name = initial.name.trim();
    if (name.isNotEmpty) return name;
    return _safe(initial.id);
  }

  String _headerSubtitle() {
    final details = _details;
    if (details != null) {
      final vehicleName = _safe(details.name);
      return vehicleName == '—' ? _safe(details.vehicleTypeName) : vehicleName;
    }
    final initial = widget.initialVehicle;
    if (initial == null) return '—';
    final name = initial.name.trim();
    if (name.isNotEmpty) return name;
    return _safe(initial.type);
  }

  String _statusLabel() {
    final details = _details;
    if (details != null) return _safe(details.statusLabel);
    final initial = widget.initialVehicle;
    if (initial == null) return '—';
    return initial.isActive ? 'Active' : 'Inactive';
  }

  Color _statusColor(ColorScheme cs) {
    final status = _statusLabel().toLowerCase();
    if (status.contains('active') || status.contains('running')) {
      return Colors.green;
    }
    if (status.contains('inactive') || status.contains('suspend')) {
      return Colors.orange;
    }
    return cs.onSurface.withValues(alpha: 0.75);
  }

  Widget _shimmerRow() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: AppShimmer(width: double.infinity, height: 18, radius: 8),
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
    double? lineGap,
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
                size: fsMeta - 1,
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
          SizedBox(height: lineGap ?? fsMain * 0.6),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                line,
                softWrap: false,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  fontSize: fsMain,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDetailsShimmer(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(spacing + 2),
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
        children: const [
          AppShimmer(width: double.infinity, height: 160, radius: 16),
          SizedBox(height: 16),
          AppShimmer(width: double.infinity, height: 140, radius: 16),
          SizedBox(height: 16),
          AppShimmer(width: double.infinity, height: 140, radius: 16),
        ],
      ),
    );
  }

  Widget _detailsCard(BuildContext context, Widget child) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _overviewCard(
    BuildContext context, {
    required String title,
    required String value,
    required Color color,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyStateCard(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
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
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: cs.onSurface.withOpacity(0.7),
            ),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(w);
    final spacing = AdaptiveUtils.getLeftSectionSpacing(w);
    final details = _details;
    final horizontalPadding = AdaptiveUtils.isVerySmallScreen(w)
        ? 12.0
        : AdaptiveUtils.isSmallScreen(w)
            ? 14.0
            : 18.0;
    final topPadding = AdaptiveUtils.isVerySmallScreen(w)
        ? 8.0
        : AdaptiveUtils.isSmallScreen(w)
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
              topPadding + AppUtils.appBarHeightCustom + 70,
              horizontalPadding,
              84,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NavigateBox(
                  selectedTab: _selectedTab,
                  tabs: _tabs,
                  title: 'Vehicle screens',
                  subtitle: 'Switch between vehicle sections below.',
                  onTabSelected: (tab) {
                    setState(() => _selectedTab = tab);
                  },
                ),
                const SizedBox(height: 16),
                _selectedTab == 'Vehicle Details'
                    ? _buildVehicleDetailsTab(
                        context,
                        details: details,
                        hp: hp,
                        spacing: spacing,
                        w: w,
                      )
                    : _selectedTab == 'Documents'
                        ? _buildDocumentsTab(context)
                        : _buildConfigTab(
                            context,
                            details: details,
                            spacing: spacing,
                            w: w,
                          ),
              ],
            ),
          ),
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            top: 0,
            child: UserHomeAppBar(
              title: _vehicleAppBarTitle(),
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

  Widget _buildVehicleDetailsTab(
    BuildContext context, {
    required UserVehicleDetails? details,
    required double hp,
    required double spacing,
    required double w,
  }) {
    final cs = Theme.of(context).colorScheme;
    final width = w;
    final scale = (width / 420).clamp(0.9, 1.0);
    final fsMain = 14 * scale;
    final fsSecondary = 12 * scale;
    final fsMeta = 11 * scale;
    final cardPadding = hp + 4;

    final name = _safe(details?.name);
    final plate = _safe(details?.plateNumber);
    final type = _safe(details?.vehicleTypeName);
    final imei = _safe(details?.imei);
    final sim = _safe(details?.simNumber);
    final vin = _safe(details?.vin);

    final device = details?.device;
    final speedVariation = _safe(device?['speedVariation']?.toString());
    final distanceVariation = _safe(device?['distanceVariation']?.toString());
    final odometer = _safe(device?['odometer']?.toString());
    final engineHours = _safe(device?['engineHours']?.toString());
    final deviceStatus = _safe(device?['status']?.toString());

    final plan = details?.plan;
    final planName = _safe(plan?['name']?.toString());
    final planPrice = _safe(plan?['price']?.toString());
    final planCurrency = _safe(plan?['currency']?.toString());
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
                            Icons.directions_car_outlined,
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
                              title: 'SIM',
                              icon: Icons.memory,
                              lines: [sim],
                              lineGap: spacing * 0.6,
                              fsMeta: fsMeta - 1,
                              fsMain: fsMain - 1,
                            ),
                            _infoCard(
                              context,
                              width: cardWidth,
                              title: 'IMEI',
                              icon: Icons.memory,
                              lines: [imei],
                              fsMeta: fsMeta - 1,
                              fsMain: fsMain - 1,
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _infoCard(
                                context,
                                width: cardWidth,
                                title: 'VIN',
                                icon: Icons.confirmation_number_outlined,
                                lines: [vin],
                                fsMeta: fsMeta - 1,
                                fsMain: fsMain - 1,
                              ),
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

  Widget _buildDocumentsTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final spacing = AdaptiveUtils.getLeftSectionSpacing(w);
    const totalDocs = 0;
    const validCount = 0;
    const warningCount = 0;
    const expiredCount = 0;

    return Column(
      children: [
        _detailsCard(
          context,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Vehicle Documents',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(0.7),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$totalDocs total',
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(w) - 1,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _overviewCard(
                      context,
                      title: 'Valid',
                      value: '$validCount',
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _overviewCard(
                      context,
                      title: 'Warning',
                      value: '$warningCount',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _overviewCard(
                      context,
                      title: 'Expired',
                      value: '$expiredCount',
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _emptyStateCard(
          context,
          title: 'No documents found',
          subtitle: 'This vehicle has no uploaded documents yet.',
        ),
      ],
    );
  }

  Widget _buildConfigTab(
    BuildContext context, {
    required UserVehicleDetails? details,
    required double spacing,
    required double w,
  }) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(width);
    final scale = (width / 420).clamp(0.9, 1.0);
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
}

class _NavigateBox extends StatelessWidget {
  final String selectedTab;
  final List<String> tabs;
  final String title;
  final String subtitle;
  final ValueChanged<String> onTabSelected;

  const _NavigateBox({
    required this.selectedTab,
    required this.tabs,
    required this.title,
    required this.subtitle,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double scale = (screenWidth / 420).clamp(0.9, 1.0);
    final double fsSection = 18 * scale;
    final double fsSubtitle = 12 * scale;
    final double fsTab = 13 * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: fsSection,
              height: 24 / 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.roboto(
              fontSize: fsSubtitle,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: tabs.map((tab) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _SmallTab(
                      label: tab,
                      selected: selectedTab == tab,
                      fontSize: fsTab,
                      onTap: () => onTabSelected(tab),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallTab extends StatelessWidget {
  final String label;
  final bool selected;
  final double? fontSize;
  final VoidCallback? onTap;

  const _SmallTab({
    required this.label,
    this.selected = false,
    this.fontSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double defaultFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth < 420 ? 10 : 14,
          vertical: screenWidth < 420 ? 5 : 6,
        ),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: fontSize ?? defaultFontSize,
            fontWeight: FontWeight.w600,
            color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
