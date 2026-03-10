import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_vehicle_details.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_vehicles_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final String vehicleId;

  const VehicleDetailsScreen({super.key, required this.vehicleId});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  // Endpoint truth table (FleetStack-API-Reference.md):
  // - GET /admin/vehicles/:id
  //   Key mapping: data.data | data.vehicle | data.item | root map.

  AdminVehicleDetails? _details;
  bool _loading = false;
  bool _errorShown = false;
  CancelToken? _token;

  ApiClient? _apiClient;
  AdminVehiclesRepository? _repo;

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
  }

  @override
  void dispose() {
    _token?.cancel('Vehicle details disposed');
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
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

  String _safe(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return '—';
    if (trimmed.toLowerCase() == 'null') return '—';
    return trimmed;
  }

  String _safeSpeed(String? value) {
    final text = _safe(value);
    if (text == '—') return text;
    if (text.toLowerCase().contains('km')) return text;
    return '$text km/h';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(w);
    final spacing = AdaptiveUtils.getLeftSectionSpacing(w);
    final titleFs = AdaptiveUtils.getTitleFontSize(w);
    final largeFs = titleFs + 2;
    final labelFs = titleFs - 2;

    final details = _details;

    final model = _safe(details?.nameModel);
    final imei = _safe(details?.imei);
    final vin = _safe(details?.vin);
    final motion = _safe(details?.status);
    final duration = _safe(details?.duration);
    final speed = _safeSpeed(details?.speed);
    final userInitials = _safe(details?.primaryUserInitials);
    final userName = _safe(details?.primaryUser);
    final lastUpdate = _safe(details?.lastUpdate);
    final fuel = _safe(details?.fuelLevel);
    final odometer = _safe(details?.odometer);
    final sim = _safe(details?.sim);
    final device = _safe(details?.deviceModel);
    final geofence = details == null || details.geofences.isEmpty
        ? '—'
        : details.geofences.join(', ');
    final active = _safe(details?.active);
    final expiry = _safe(details?.expiry);

    final statusColor = motion.toLowerCase().contains('run')
        ? Colors.green
        : cs.onSurface;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(hp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Vehicle Details',
                    style: GoogleFonts.inter(
                      fontSize: titleFs,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              SizedBox(height: spacing * 1.5),

              Center(
                child: Column(
                  children: [
                    _loading
                        ? const AppShimmer(width: 220, height: 22, radius: 10)
                        : Text(
                            model,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: largeFs,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    SizedBox(height: spacing / 2),
                    _loading
                        ? const AppShimmer(width: 260, height: 14, radius: 8)
                        : Text(
                            'IMEI: $imei · VIN: $vin',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: labelFs,
                              color: cs.onSurface.withOpacity(0.65),
                            ),
                          ),
                  ],
                ),
              ),

              SizedBox(height: spacing * 2),

              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.6,
                children: [
                  _infoBox(
                    context,
                    title: 'Status',
                    value: motion,
                    subtitle: '[$duration]',
                    icon: CupertinoIcons.arrow_right,
                    color: statusColor,
                    loading: _loading,
                  ),
                  _infoBox(
                    context,
                    title: 'Speed',
                    value: speed,
                    icon: CupertinoIcons.speedometer,
                    loading: _loading,
                  ),
                  _infoBox(
                    context,
                    title: 'Primary User',
                    value: '$userInitials $userName',
                    icon: CupertinoIcons.person_fill,
                    loading: _loading,
                  ),
                  _infoBox(
                    context,
                    title: 'Last Update',
                    value: lastUpdate,
                    icon: CupertinoIcons.time,
                    loading: _loading,
                  ),
                ],
              ),

              SizedBox(height: spacing * 2),

              _sectionContainer(
                context,
                title: 'Device & SIM',
                children: [
                  _row('Fuel Level', fuel, loading: _loading),
                  _row('Odometer', odometer, loading: _loading),
                  _row('SIM', sim, loading: _loading),
                  _row('Device Model', device, loading: _loading),
                  _row('Geo Fences', geofence, loading: _loading),
                ],
              ),

              SizedBox(height: spacing * 2),

              _sectionContainer(
                context,
                title: 'Security',
                children: [
                  _securityRow(
                    'Ignition',
                    details?.ignitionOk,
                    loading: _loading,
                  ),
                  _securityRow('GPS', details?.gpsOk, loading: _loading),
                  _securityRow('Lock', details?.lockOk, loading: _loading),
                ],
              ),

              SizedBox(height: spacing * 2),

              _sectionContainer(
                context,
                title: 'Subscription',
                children: [
                  _row('Active', active, loading: _loading),
                  _row('Expiry', expiry, loading: _loading),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBox(
    BuildContext context, {
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    Color? color,
    required bool loading,
  }) {
    final cs = Theme.of(context).colorScheme;
    final titleFs = AdaptiveUtils.getTitleFontSize(
      MediaQuery.of(context).size.width,
    );
    final labelFs = titleFs - 2;
    final smallFs = titleFs - 4;
    final mediumPadding =
        AdaptiveUtils.getHorizontalPadding(MediaQuery.of(context).size.width) *
        0.8;
    final iconSize = titleFs + 6;

    return Container(
      padding: EdgeInsets.all(mediumPadding),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color ?? cs.primary, size: iconSize),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: smallFs + 2,
              color: cs.onSurface.withOpacity(0.6),
            ),
          ),
          loading
              ? const AppShimmer(width: 100, height: 16, radius: 8)
              : Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: labelFs + 4,
                    fontWeight: FontWeight.bold,
                    color: color ?? cs.onSurface,
                  ),
                ),
          const SizedBox(height: 5),
          if (subtitle != null)
            loading
                ? const AppShimmer(width: 80, height: 12, radius: 6)
                : Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: smallFs + 2,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _sectionContainer(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final cs = Theme.of(context).colorScheme;
    final titleFs = AdaptiveUtils.getTitleFontSize(
      MediaQuery.of(context).size.width,
    );
    final labelFs = titleFs - 2;
    final smallPadding =
        AdaptiveUtils.getHorizontalPadding(MediaQuery.of(context).size.width) *
        0.5;
    final largePadding = AdaptiveUtils.getHorizontalPadding(
      MediaQuery.of(context).size.width,
    );

    return Container(
      padding: EdgeInsets.all(largePadding),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
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
              fontSize: labelFs,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: smallPadding * 2),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {required bool loading}) {
    final w = MediaQueryData.fromView(
      WidgetsBinding.instance.window,
    ).size.width;
    final titleFs = AdaptiveUtils.getTitleFontSize(w);
    final smallFs = titleFs - 4;
    final smallPadding = AdaptiveUtils.getHorizontalPadding(w) * 0.5;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: smallPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: smallFs,
              color: Colors.grey.shade600,
            ),
          ),
          loading
              ? const AppShimmer(width: 120, height: 12, radius: 6)
              : Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: smallFs,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _securityRow(String label, bool? enabled, {required bool loading}) {
    final w = MediaQueryData.fromView(
      WidgetsBinding.instance.window,
    ).size.width;
    final titleFs = AdaptiveUtils.getTitleFontSize(w);
    final labelFs = titleFs - 2;
    final smallPadding = AdaptiveUtils.getHorizontalPadding(w) * 0.5;
    final iconSize = titleFs + 6;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: smallPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: labelFs)),
          if (loading)
            const AppShimmer(width: 16, height: 16, radius: 8)
          else if (enabled == null)
            Text(
              '—',
              style: GoogleFonts.inter(
                fontSize: labelFs,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Icon(
              enabled
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.xmark_circle_fill,
              color: enabled ? Colors.green : Colors.red,
              size: iconSize,
            ),
        ],
      ),
    );
  }
}
