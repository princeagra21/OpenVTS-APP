// components/vehicle/vehicle_config_tab.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/vehicle_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleConfigTab extends StatefulWidget {
  final String? vehicleId;
  final Map<String, dynamic>? initialConfigRaw;

  const VehicleConfigTab({super.key, this.vehicleId, this.initialConfigRaw});

  @override
  State<VehicleConfigTab> createState() => _VehicleConfigTabState();
}

class _VehicleConfigTabState extends State<VehicleConfigTab> {
  final TextEditingController speedController = TextEditingController(
    text: "1.00",
  );
  final TextEditingController distanceController = TextEditingController(
    text: "1.00",
  );
  final TextEditingController odometerController = TextEditingController(
    text: "0",
  );
  final TextEditingController engineHoursController = TextEditingController(
    text: "0",
  );

  String ignitionSource = "Ignition Wire";
  bool _loading = false;
  bool _saving = false;
  bool _missingVehicleIdShown = false;
  CancelToken? _saveToken;
  ApiClient? _api;
  SuperadminRepository? _repo;

  String _snapSpeed = "1.00";
  String _snapDistance = "1.00";
  String _snapOdometer = "0";
  String _snapEngineHours = "0";
  String _snapIgnition = "Ignition Wire";

  @override
  void initState() {
    super.initState();
    _hydrateInitialConfig();
    if (widget.vehicleId == null || widget.vehicleId!.trim().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (kDebugMode && !_missingVehicleIdShown) {
          _missingVehicleIdShown = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Vehicle ID missing. Save disabled, using defaults.',
              ),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _saveToken?.cancel('VehicleConfigTab save disposed');
    speedController.dispose();
    distanceController.dispose();
    odometerController.dispose();
    engineHoursController.dispose();
    super.dispose();
  }

  String? get _vehicleId => widget.vehicleId?.trim().isNotEmpty == true
      ? widget.vehicleId!.trim()
      : null;

  void _applySnapshot() {
    speedController.text = _snapSpeed;
    distanceController.text = _snapDistance;
    odometerController.text = _snapOdometer;
    engineHoursController.text = _snapEngineHours;
    ignitionSource = _snapIgnition;
  }

  void _saveSnapshotFromControllers() {
    _snapSpeed = speedController.text.trim().isNotEmpty
        ? speedController.text.trim()
        : _snapSpeed;
    _snapDistance = distanceController.text.trim().isNotEmpty
        ? distanceController.text.trim()
        : _snapDistance;
    _snapOdometer = odometerController.text.trim().isNotEmpty
        ? odometerController.text.trim()
        : _snapOdometer;
    _snapEngineHours = engineHoursController.text.trim().isNotEmpty
        ? engineHoursController.text.trim()
        : _snapEngineHours;
    _snapIgnition = ignitionSource;
  }

  void _hydrateInitialConfig() {
    final raw = widget.initialConfigRaw;
    if (raw == null || raw.isEmpty) {
      _saveSnapshotFromControllers();
      return;
    }

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

    speedController.text = (speed ?? 1).toStringAsFixed(2);
    distanceController.text = (distance ?? 1).toStringAsFixed(2);
    odometerController.text = ((odo ?? 0).toStringAsFixed(0));
    engineHoursController.text = ((hours ?? 0).toStringAsFixed(0));
    _saveSnapshotFromControllers();
  }

  Future<void> _saveConfig() async {
    final vehicleId = _vehicleId;
    if (vehicleId == null) {
      return;
    }

    final speed = double.tryParse(speedController.text.trim());
    final distance = double.tryParse(distanceController.text.trim());
    final odometer = double.tryParse(odometerController.text.trim());
    final engineHours = double.tryParse(engineHoursController.text.trim());

    if (speed == null ||
        distance == null ||
        odometer == null ||
        engineHours == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numeric values.')),
      );
      return;
    }

    _saveToken?.cancel('Previous save vehicle config');
    final token = CancelToken();
    _saveToken = token;

    if (!mounted) return;
    setState(() => _saving = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);
      final payload = VehicleConfigUpdate(
        speedMultiplier: speed,
        distanceMultiplier: distance,
        odometer: odometer,
        engineHours: engineHours,
      );

      final res = await _repo!.updateVehicleConfig(
        vehicleId,
        payload,
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (_) {
          if (!mounted) return;
          setState(() {
            _saving = false;
            _saveSnapshotFromControllers();
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Saved')));
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _saving = false);
          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to save config.'
              : "Couldn't save config.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't save config.")));
    }
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

  Widget _numberField({
    required TextEditingController controller,
    required String unit,
    double step = 0.01,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double fs = AdaptiveUtils.getTitleFontSize(width);

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.inter(fontSize: fs, color: colorScheme.onSurface),
      decoration: InputDecoration(
        filled: true,
        fillColor: colorScheme.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => _increment(controller, step),
                  child: Icon(
                    Icons.arrow_drop_up,
                    size: 18,
                    color: colorScheme.onSurface,
                  ),
                ),
                InkWell(
                  onTap: () => _decrement(controller, step),
                  child: Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              unit,
              style: GoogleFonts.inter(
                fontSize: fs,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface.withOpacity(0.87),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
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
            style: GoogleFonts.inter(
              fontSize: fs + 2,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
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
            "Ignition Source",
            style: GoogleFonts.inter(
              fontSize: fs + 2,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Choose how engine ON/OFF is derived.",
            style: GoogleFonts.inter(
              fontSize: fs - 2,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  activeColor: colorScheme.primary,
                  title: Text(
                    "Ignition Wire",
                    style: GoogleFonts.inter(
                      fontSize: fs - 1,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  value: "Ignition Wire",
                  groupValue: ignitionSource,
                  onChanged: (v) =>
                      v != null ? setState(() => ignitionSource = v) : null,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  activeColor: colorScheme.primary,
                  title: Text(
                    "Motion-Based",
                    style: GoogleFonts.inter(
                      fontSize: fs - 1,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  value: "Motion-Based",
                  groupValue: ignitionSource,
                  onChanged: (v) =>
                      v != null ? setState(() => ignitionSource = v) : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double fs = AdaptiveUtils.getTitleFontSize(width);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                onPressed: () => setState(_applySnapshot),
                child: Text(
                  "Reset",
                  style: GoogleFonts.inter(
                    fontSize: fs - 2,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                onPressed: (_saving || _vehicleId == null) ? null : _saveConfig,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: _saving
                          ? CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.onPrimary,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    if (_saving) const SizedBox(width: 8),
                    Text(
                      "Save",
                      style: GoogleFonts.inter(
                        fontSize: fs - 2,
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                "Vehicle Setting Configuration",
                style: GoogleFonts.inter(
                  fontSize: fs + 1,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 12,
                height: 12,
                child: _loading
                    ? CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _configBox(
            title: "Speed Multiplier (×)",
            subtitle:
                "Multiply raw speed by this factor (e.g., 0.95, 1.00, 1.05).",
            controller: speedController,
            unit: "×",
          ),
          _configBox(
            title: "Distance Multiplier (×)",
            subtitle:
                "Multiply raw distance by this factor (e.g., 0.98, 1.00, 1.10).",
            controller: distanceController,
            unit: "×",
          ),
          _configBox(
            title: "Set Odometer",
            subtitle: "Override odometer baseline (km).",
            controller: odometerController,
            unit: "km",
            step: 1,
          ),
          _configBox(
            title: "Set Engine Hours",
            subtitle: "Total engine runtime hours.",
            controller: engineHoursController,
            unit: "h",
            step: 1,
          ),
          _ignitionSourceBox(),
        ],
      ),
    );
  }
}
