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
import 'package:flutter/cupertino.dart';
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

  ApiClient? _apiClient;
  UserVehiclesRepository? _repo;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _token?.cancel('User vehicle details disposed');
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
    setState(() => _loading = true);

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
        });
      },
      failure: (error) {
        setState(() => _loading = false);
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

  Widget _section(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(w);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              fontWeight: FontWeight.w700,
              fontSize: AdaptiveUtils.getSubtitleFontSize(w) - 2,
              color: cs.onSurface,
            ),
          ),
          SizedBox(height: hp * 0.7),
          ...children,
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final fs = AdaptiveUtils.getTitleFontSize(w);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: fs,
                color: cs.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: fs,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerRow() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: AppShimmer(width: double.infinity, height: 18, radius: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(w);
    final spacing = AdaptiveUtils.getLeftSectionSpacing(w);
    final details = _details;

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
                      fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: spacing * 1.2),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(hp),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
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
                          width: AdaptiveUtils.getAvatarSize(w),
                          height: AdaptiveUtils.getAvatarSize(w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.primary.withValues(alpha: 0.1),
                          ),
                          child: Icon(
                            CupertinoIcons.car_detailed,
                            size: AdaptiveUtils.getIconSize(w),
                            color: cs.primary,
                          ),
                        ),
                        SizedBox(width: spacing * 1.5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _loading
                                  ? const AppShimmer(
                                      width: 180,
                                      height: 20,
                                      radius: 8,
                                    )
                                  : Text(
                                      _headerTitle(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize:
                                            AdaptiveUtils.getSubtitleFontSize(
                                              w,
                                            ) -
                                            1,
                                        fontWeight: FontWeight.bold,
                                        color: cs.onSurface,
                                      ),
                                    ),
                              const SizedBox(height: 8),
                              _loading
                                  ? const AppShimmer(
                                      width: 220,
                                      height: 14,
                                      radius: 8,
                                    )
                                  : Text(
                                      _headerSubtitle(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize:
                                            AdaptiveUtils.getTitleFontSize(w),
                                        color: cs.onSurface.withValues(
                                          alpha: 0.68,
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _loading
                            ? const AppShimmer(
                                width: 82,
                                height: 28,
                                radius: 14,
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(
                                    cs,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _statusLabel(),
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    color: _statusColor(cs),
                                  ),
                                ),
                              ),
                      ],
                    ),
                    SizedBox(height: spacing),
                    _loading
                        ? const AppShimmer(
                            width: double.infinity,
                            height: 16,
                            radius: 8,
                          )
                        : Text(
                            'Vehicle ID: ${_safe(details?.id ?? widget.initialVehicle?.id)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: AdaptiveUtils.getTitleFontSize(w),
                              color: cs.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                  ],
                ),
              ),
              SizedBox(height: spacing * 1.4),
              _section(
                context,
                title: 'Vehicle Info',
                children: _loading
                    ? [
                        _shimmerRow(),
                        _shimmerRow(),
                        _shimmerRow(),
                        _shimmerRow(),
                        _shimmerRow(),
                        _shimmerRow(),
                      ]
                    : [
                        _row(context, 'Plate', _safe(details?.plateNumber)),
                        _row(context, 'Name', _safe(details?.name)),
                        _row(context, 'VIN', _safe(details?.vin)),
                        _row(context, 'IMEI', _safe(details?.imei)),
                        _row(context, 'SIM', _safe(details?.simNumber)),
                        _row(context, 'Type', _safe(details?.vehicleTypeName)),
                      ],
              ),
              SizedBox(height: spacing * 1.4),
              _section(
                context,
                title: 'Configuration',
                children: _loading
                    ? [_shimmerRow(), _shimmerRow()]
                    : [
                        _row(context, 'GMT', _safe(details?.gmtOffset)),
                        _row(
                          context,
                          'Created',
                          _formatDateTime(details?.createdAt),
                        ),
                      ],
              ),
              SizedBox(height: spacing * 1.4),
              _section(
                context,
                title: 'Device',
                children: _loading
                    ? [
                        _shimmerRow(),
                        _shimmerRow(),
                        _shimmerRow(),
                        _shimmerRow(),
                        _shimmerRow(),
                        _shimmerRow(),
                      ]
                    : [
                        _row(context, 'Device ID', _safe(details?.deviceId)),
                        _row(
                          context,
                          'Device IMEI',
                          _safe(details?.deviceImei),
                        ),
                        _row(
                          context,
                          'Speed Var.',
                          _safe(details?.speedVariation),
                        ),
                        _row(
                          context,
                          'Distance Var.',
                          _safe(details?.distanceVariation),
                        ),
                        _row(context, 'Odometer', _safe(details?.odometer)),
                        _row(
                          context,
                          'Engine Hours',
                          _safe(details?.engineHours),
                        ),
                        _row(
                          context,
                          'Ignition',
                          _safe(details?.ignitionSource),
                        ),
                      ],
              ),
              SizedBox(height: spacing * 1.4),
              _section(
                context,
                title: 'Plan',
                children: _loading
                    ? [_shimmerRow(), _shimmerRow()]
                    : [
                        _row(context, 'Plan', _safe(details?.planName)),
                        _row(
                          context,
                          'Price',
                          _formatAmount(
                            details?.planPrice,
                            details?.planCurrency ?? '',
                          ),
                        ),
                      ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
