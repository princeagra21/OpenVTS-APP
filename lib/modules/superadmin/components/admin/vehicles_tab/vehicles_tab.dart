// components/admin/vehicles_tab/vehicles_tab.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_vehicle_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/vehicles_tab/vehicle_card.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VehiclesTab extends StatefulWidget {
  final String adminId;

  const VehiclesTab({super.key, required this.adminId});

  @override
  State<VehiclesTab> createState() => _VehiclesTabState();
}

class _VehiclesTabState extends State<VehiclesTab> {
  late List<Map<String, dynamic>> _vehiclesData;
  bool _loading = false;
  bool _errorShown = false;
  CancelToken? _token;

  ApiClient? _api;
  SuperadminRepository? _repo;

  final List<Map<String, dynamic>> _fallbackVehiclesData = [
    {
      "name": "Atlas T-900",
      "type": "Truck",
      "isActive": false,
      "imei": "862045317896420",
      "vin": "MAT448123C5200456",
      "model": "GT06",
      "lastSeenDate": "2025-10-16",
      "lastSeenTime": "06:41",
      "timezone": "+5:30",
      "primaryExpiry": "2026-04-30",
      "secondaryExpiry": "2027-04-30",
    },
    {
      "name": "CargoJet V8",
      "type": "Truck",
      "isActive": false,
      "imei": "865431200987654",
      "vin": "MBHZZZ8P7GT201245",
      "model": "GT06",
      "lastSeenDate": "2025-10-16",
      "lastSeenTime": "13:40",
      "timezone": "+5:30",
      "primaryExpiry": "2026-03-31",
      "secondaryExpiry": "2027-03-31",
    },
    {
      "name": "CargoMax K2",
      "type": "Truck",
      "isActive": false,
      "imei": "355488120563742",
      "vin": "MBHZZZ8P7GT200112",
      "model": "GT06",
      "lastSeenDate": "2025-10-16",
      "lastSeenTime": "07:52",
      "timezone": "+5:30",
      "primaryExpiry": "2026-11-30",
      "secondaryExpiry": "2027-11-30",
    },
    // ... more vehicles
  ];

  @override
  void initState() {
    super.initState();
    _vehiclesData = List<Map<String, dynamic>>.from(_fallbackVehiclesData);
    _loadVehicles();
  }

  @override
  void dispose() {
    _token?.cancel('VehiclesTab disposed');
    super.dispose();
  }

  Map<String, dynamic> _mapVehicle(AdminVehicleItem v) {
    final name = v.name.isNotEmpty
        ? v.name
        : (v.plateNumber.isNotEmpty ? v.plateNumber : '—');
    final type = '';
    final lastSeenDate = v.updatedAt.isNotEmpty ? v.updatedAt : '';

    return <String, dynamic>{
      "name": name,
      "type": type.isNotEmpty ? type : "Vehicle",
      "isActive": v.isActive,
      "imei": v.imei,
      "vin": "",
      "model": "",
      "lastSeenDate": lastSeenDate,
      "lastSeenTime": "",
      "timezone": "",
      "primaryExpiry": "2099-01-01",
      "secondaryExpiry": "2099-01-01",
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
            _vehiclesData = mapped;
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _loading = false);
          if (_errorShown) return;
          _errorShown = true;

          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to view vehicles.'
              : "Couldn't load vehicles. Showing fallback list.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't load vehicles. Showing fallback list."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showNoData = !_loading && _vehiclesData.isEmpty;
    final displayVehicles = showNoData
        ? <Map<String, dynamic>>[
            {
              "name": "No vehicles",
              "type": "",
              "isActive": false,
              "imei": "",
              "vin": "",
              "model": "",
              "lastSeenDate": "",
              "lastSeenTime": "",
              "timezone": "",
              "primaryExpiry": "2099-01-01",
              "secondaryExpiry": "2099-01-01",
            },
          ]
        : _vehiclesData;
    return Column(
      children: [
        _buildOverviewCard(context, colorScheme),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: displayVehicles
                .map(
                  (v) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: VehicleCard(
                      name: v["name"],
                      type: v["type"],
                      isActive: v["isActive"],
                      imei: v["imei"],
                      vin: v["vin"],
                      model: v["model"],
                      lastSeenDate: v["lastSeenDate"],
                      lastSeenTime: v["lastSeenTime"],
                      timezone: v["timezone"],
                      primaryExpiry: v["primaryExpiry"],
                      secondaryExpiry: v["secondaryExpiry"],
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
    final double changeFontSize = subtitleFontSize - 1;

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
          // TOP ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Vehicles",
                style: GoogleFonts.inter(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.7),
                  letterSpacing: 0.8,
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "${_vehiclesData.length}",
                      style: GoogleFonts.inter(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (_loading)
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "currently tracked",
            style: GoogleFonts.inter(
              fontSize: subtitleFontSize,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.7),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: colorScheme.onSurface.withOpacity(0.1)),
          const SizedBox(height: 20),
          // STATUS ROWS
          _buildStatusRow(
            label: "Moving",
            value: "432",
            change: "▲ 3.8%",
            color: Colors.green,
            labelFontSize: titleFontSize,
            valueFontSize: valueFontSize - 12,
            changeFontSize: changeFontSize,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 16),
          _buildStatusRow(
            label: "Idle",
            value: "215",
            change: "▼ 1.2%",
            color: Colors.orange,
            labelFontSize: titleFontSize,
            valueFontSize: valueFontSize - 12,
            changeFontSize: changeFontSize,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 16),
          _buildStatusRow(
            label: "Stopped",
            value: "190",
            change: "▼ 0.6%",
            color: Colors.red,
            labelFontSize: titleFontSize,
            valueFontSize: valueFontSize - 12,
            changeFontSize: changeFontSize,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required String label,
    required String value,
    required String change,
    required Color color,
    required double labelFontSize,
    required double valueFontSize,
    required double changeFontSize,
    required ColorScheme colorScheme,
  }) {
    final isNegative = change.contains('▼');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: labelFontSize,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: valueFontSize,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              isNegative ? Icons.arrow_downward : Icons.arrow_upward,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              change,
              style: GoogleFonts.inter(
                fontSize: changeFontSize,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
