// components/admin/vehicles_tab/vehicles_tab.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_vehicle_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/vehicles_tab/vehicle_card.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class VehiclesTab extends StatefulWidget {
  final String adminId;

  const VehiclesTab({super.key, required this.adminId});

  @override
  State<VehiclesTab> createState() => _VehiclesTabState();
}

class _VehiclesTabState extends State<VehiclesTab> {
  final List<Map<String, dynamic>> _vehiclesData = <Map<String, dynamic>>[];
  bool _loading = false;
  bool _errorShown = false;
  bool _loadFailed = false;
  CancelToken? _token;

  ApiClient? _api;
  SuperadminRepository? _repo;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void dispose() {
    _token?.cancel('VehiclesTab disposed');
    super.dispose();
  }

  String _safeString(Object? value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;

    final iso = DateTime.tryParse(text);
    if (iso != null) return iso;

    const patterns = ['dd MMM yyyy', 'yyyy-MM-dd', 'dd-MM-yyyy'];
    for (final pattern in patterns) {
      try {
        return DateFormat(pattern).parseStrict(text);
      } catch (_) {
        // continue
      }
    }
    return null;
  }

  String _formatDateOrRaw(Object? value) {
    final parsed = _parseDate(value);
    if (parsed != null) return DateFormat('dd MMM yyyy').format(parsed);
    return _safeString(value);
  }

  String _formatTimeOrDash(Object? value) {
    final parsed = _parseDate(value);
    if (parsed != null) return DateFormat('HH:mm').format(parsed);
    return '-';
  }

  bool _resolveIsActive(AdminVehicleItem v) {
    final raw = v.raw;
    final active = raw['isActive'] ?? raw['active'] ?? raw['is_active'];

    if (active is bool) return active;
    if (active is num) return active != 0;
    if (active is String) {
      final t = active.trim().toLowerCase();
      if (t == 'true' || t == '1' || t == 'active') return true;
      if (t == 'false' || t == '0' || t == 'inactive') return false;
    }

    final status = (raw['status'] ?? raw['state'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (status == 'active') return true;
    if (status == 'inactive') return false;

    // API may omit status flags for admin vehicle listing; default to active.
    return true;
  }

  Map<String, dynamic> _mapVehicle(AdminVehicleItem v) {
    final raw = v.raw;

    final type = _safeString(v.type);
    final name = _safeString(
      v.name.isNotEmpty
          ? v.name
          : (v.plateNumber.isNotEmpty ? v.plateNumber : null),
    );

    final lastSeenSource =
        raw['updatedAt'] ??
        raw['lastSeenAt'] ??
        raw['lastActivityAt'] ??
        raw['createdAt'];

    final isActive = _resolveIsActive(v);

    return <String, dynamic>{
      'name': name,
      'type': type,
      'isActive': isActive,
      'imei': _safeString(v.imei),
      'plate': _safeString(v.plateNumber),
      'vin': _safeString(v.vin),
      'simNumber': _safeString(v.simNumber),
      'model': _safeString(
        raw['model'] ?? raw['deviceModel'] ?? raw['deviceType'],
      ),
      'lastSeenDate': _formatDateOrRaw(lastSeenSource),
      'lastSeenTime': _formatTimeOrDash(lastSeenSource),
      'timezone': _safeString(raw['gmtOffset'] ?? raw['timezone']),
      'primaryExpiry': _formatDateOrRaw(
        raw['primaryExpiry'] ??
            raw['primaryLicenseExpiry'] ??
            raw['license_pri'],
      ),
      'secondaryExpiry': _formatDateOrRaw(
        raw['secondaryExpiry'] ??
            raw['secondaryLicenseExpiry'] ??
            raw['license_sec'],
      ),
    };
  }

  Future<void> _loadVehicles() async {
    _token?.cancel('Reload admin vehicles');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final res = await _repo!.getAdminVehicles(
        widget.adminId,
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (items) {
          if (!mounted) return;
          final mapped = items.map(_mapVehicle).toList();
          setState(() {
            _loading = false;
            _errorShown = false;
            _loadFailed = false;
            _vehiclesData
              ..clear()
              ..addAll(mapped);
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _loadFailed = true;
            _vehiclesData.clear();
          });
          if (_errorShown) return;
          _errorShown = true;

          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to view vehicles.'
              : "Couldn't load vehicles.";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () {
                  _errorShown = false;
                  _loadVehicles();
                },
              ),
            ),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
        _vehiclesData.clear();
      });
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Couldn't load vehicles."),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () {
              _errorShown = false;
              _loadVehicles();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showNoData = !_loading && _vehiclesData.isEmpty;

    return Column(
      children: [
        _buildOverviewCard(context, colorScheme),
        const SizedBox(height: 24),
        if (showNoData)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _loadFailed ? "Couldn't load vehicles." : 'No vehicles found',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                if (!_loadFailed) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Try adjusting search or ask superadmin to assign vehicles.',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.72),
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (_loading)
          ...List<Widget>.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildVehicleCardSkeleton(colorScheme),
            ),
          ),
        if (!showNoData && !_loading)
          Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: _vehiclesData
                  .map(
                    (v) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: VehicleCard(
                        name: v['name'] as String,
                        type: v['type'] as String,
                        isActive: v['isActive'] == true,
                        plate: v['plate'] as String,
                        imei: v['imei'] as String,
                        vin: v['vin'] as String,
                        simNumber: v['simNumber'] as String,
                        model: v['model'] as String,
                        lastSeenDate: v['lastSeenDate'] as String,
                        lastSeenTime: v['lastSeenTime'] as String,
                        timezone: v['timezone'] as String,
                        primaryExpiry: v['primaryExpiry'] as String,
                        secondaryExpiry: v['secondaryExpiry'] as String,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildOverviewCard(BuildContext context, ColorScheme colorScheme) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double titleFontSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double valueFontSize = titleFontSize * 2;
    final double subtitleFontSize = titleFontSize - 2;

    final total = _vehiclesData.length;
    final active = _vehiclesData.where((v) => v['isActive'] == true).length;
    final inactive = _vehiclesData.where((v) => v['isActive'] != true).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
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
                'Total Vehicles',
                style: GoogleFonts.roboto(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.7),
                  letterSpacing: 0.8,
                ),
              ),
              _loading
                  ? AppShimmer(
                      width: valueFontSize * 0.9,
                      height: valueFontSize * 0.8,
                      radius: 8,
                    )
                  : Text(
                      '$total',
                      style: GoogleFonts.roboto(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'currently tracked',
            style: GoogleFonts.roboto(
              fontSize: subtitleFontSize,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.7),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: colorScheme.onSurface.withOpacity(0.1)),
          const SizedBox(height: 20),
          if (_loading) ...[
            _buildStatusSkeleton(),
            const SizedBox(height: 16),
            _buildStatusSkeleton(),
          ] else ...[
            _buildStatusRow(
              label: 'Active',
              value: '$active',
              color: colorScheme.primary,
              labelFontSize: titleFontSize,
              valueFontSize: valueFontSize - 12,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),
            _buildStatusRow(
              label: 'Inactive',
              value: '$inactive',
              color: colorScheme.error,
              labelFontSize: titleFontSize,
              valueFontSize: valueFontSize - 12,
              colorScheme: colorScheme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required String label,
    required String value,
    required Color color,
    required double labelFontSize,
    required double valueFontSize,
    required ColorScheme colorScheme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: labelFontSize,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: valueFontSize,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusSkeleton() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppShimmer(width: 90, height: 18, radius: 8),
        AppShimmer(width: 64, height: 20, radius: 8),
      ],
    );
  }

  Widget _buildVehicleCardSkeleton(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppShimmer(width: 140, height: 18, radius: 8),
              AppShimmer(width: 76, height: 18, radius: 9),
            ],
          ),
          SizedBox(height: 12),
          AppShimmer(width: 170, height: 16, radius: 8),
          SizedBox(height: 8),
          AppShimmer(width: double.infinity, height: 14, radius: 8),
          SizedBox(height: 6),
          AppShimmer(width: double.infinity, height: 14, radius: 8),
          SizedBox(height: 6),
          AppShimmer(width: double.infinity, height: 14, radius: 8),
          SizedBox(height: 12),
          AppShimmer(width: 120, height: 16, radius: 8),
          SizedBox(height: 8),
          AppShimmer(width: double.infinity, height: 14, radius: 8),
          SizedBox(height: 6),
          AppShimmer(width: double.infinity, height: 14, radius: 8),
        ],
      ),
    );
  }
}
