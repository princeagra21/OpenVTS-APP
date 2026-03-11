// components/vehicle/widget/vehicle_map_tab.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:flutter/foundation.dart';

class VehicleMapTab extends StatefulWidget {
  final String? imei;
  final LatLng fallbackLocation;
  final String vehiclePlate;

  const VehicleMapTab({
    super.key,
    this.imei,
    required this.fallbackLocation,
    this.vehiclePlate = "Vehicle",
  });

  @override
  State<VehicleMapTab> createState() => _VehicleMapTabState();
}

class _VehicleMapTabState extends State<VehicleMapTab> {
  final MapController _mapController = MapController();
  LatLng? _vehicleLocation;
  bool _loading = false;
  bool _errorShown = false;
  bool _missingImeiShown = false;
  CancelToken? _token;
  ApiClient? _api;
  SuperadminRepository? _repo;
  String _label = '';

  LatLng get _resolvedLocation => _vehicleLocation ?? widget.fallbackLocation;

  @override
  void initState() {
    super.initState();
    _label = widget.vehiclePlate;
    _loadLocation();
  }

  @override
  void dispose() {
    _token?.cancel('VehicleMapTab disposed');
    super.dispose();
  }

  Future<void> _loadLocation() async {
    final imei = widget.imei?.trim() ?? '';
    if (imei.isEmpty) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (kDebugMode && !_missingImeiShown) {
        _missingImeiShown = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('IMEI not available. Using fallback map.'),
          ),
        );
      }
      return;
    }

    _token?.cancel('Reload vehicle location');
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
      final res = await _repo!.getVehicleLocation(imei, cancelToken: token);

      if (!mounted) return;
      res.when(
        success: (location) {
          if (!mounted) return;
          final point = location.hasValidPoint
              ? LatLng(location.lat, location.lng)
              : widget.fallbackLocation;

          final updatedLabel = location.updatedAt.isNotEmpty
              ? '${widget.vehiclePlate} • ${location.updatedAt}'
              : widget.vehiclePlate;

          setState(() {
            _vehicleLocation = point;
            _label = updatedLabel;
            _loading = false;
            _errorShown = false;
          });
          _mapController.move(point, 15.0);
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _loading = false);
          if (_errorShown) return;
          _errorShown = true;
          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to view location.'
              : "Couldn't load location. Showing fallback.";
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
          content: Text("Couldn't load location. Showing fallback."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: constraints.maxHeight.isInfinite
                ? MediaQuery.of(context).size.height
                : constraints.maxHeight,
          ),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _resolvedLocation,
              initialZoom: 15.0,
              minZoom: 3,
              maxZoom: 18,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.fleek_stack_mobile',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _resolvedLocation,
                    width: 170,
                    height: 140,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withOpacity(0.98),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.primary,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  _label,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: _loading
                                    ? const AppShimmer(
                                        width: 12,
                                        height: 12,
                                        radius: 6,
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          Icons.location_on,
                          size: 52,
                          color: colorScheme.primary,
                          shadows: const [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
