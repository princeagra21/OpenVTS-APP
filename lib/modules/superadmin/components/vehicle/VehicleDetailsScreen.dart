// screens/vehicle/vehicle_details_screen.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/vehicle_details.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/navigate.dart';
import 'package:fleet_stack/modules/superadmin/components/vehicle/widget/send_command.dart';
import 'package:fleet_stack/modules/superadmin/components/vehicle/widget/vehicle_config_tab.dart';
import 'package:fleet_stack/modules/superadmin/components/vehicle/widget/vehicle_details_tab.dart';
import 'package:fleet_stack/modules/superadmin/components/vehicle/widget/vehicle_documents_tab.dart';
import 'package:fleet_stack/modules/superadmin/components/vehicle/widget/vehicle_logs_tab.dart';
import 'package:fleet_stack/modules/superadmin/components/vehicle/widget/vehicle_map_tab.dart';
import 'package:fleet_stack/modules/superadmin/components/vehicle/widget/vehicle_users_tab.dart';
import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final String id;

  const VehicleDetailsScreen({super.key, required this.id});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  String selectedTab = "Vehicle Details";

  final List<String> tabs = [
    "Vehicle Details",
    "Vehicle Users",
    "Send Commands",
    "Logs",
    "Maps",
    "Documents",
    "Vehicle Config",
  ];

  VehicleDetails? _details;
  bool _loadingDetails = false;
  bool _errorShown = false;
  CancelToken? _detailsToken;

  ApiClient? _api;
  SuperadminRepository? _repo;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _detailsToken?.cancel('VehicleDetailsScreen disposed');
    super.dispose();
  }

  Future<void> _loadDetails() async {
    _detailsToken?.cancel('Reload vehicle details');
    final token = CancelToken();
    _detailsToken = token;

    if (!mounted) return;
    setState(() => _loadingDetails = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final res = await _repo!.getVehicleDetails(widget.id, cancelToken: token);
      if (!mounted) return;

      res.when(
        success: (d) {
          if (!mounted) return;
          setState(() {
            _details = d;
            _loadingDetails = false;
            _errorShown = false;
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _loadingDetails = false);
          if (_errorShown) return;
          _errorShown = true;
          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to view vehicle.'
              : "Couldn't load vehicle. Showing fallback info.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDetails = false);
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't load vehicle. Showing fallback info."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double fs = AdaptiveUtils.getTitleFontSize(width);

    final plate = _details?.plate.isNotEmpty == true
        ? _details!.plate
        : "DL01 AB 1287";
    final status = _details?.status.isNotEmpty == true
        ? _details!.status
        : "RUNNING";
    final model = _details?.model.isNotEmpty == true ? _details!.model : "GT06";
    final type = _details?.type.isNotEmpty == true ? _details!.type : "Truck";

    final lastSeen = _details?.lastSeen.isNotEmpty == true
        ? _details!.lastSeen
        : "2 min ago";
    final speed = _details?.speed.isNotEmpty == true
        ? _details!.speed
        : "68 km/h";
    final ignition = _details?.ignition.isNotEmpty == true
        ? _details!.ignition
        : "ON";
    final location = _details?.locationName.isNotEmpty == true
        ? _details!.locationName
        : "Mumbai, MH";

    return AppLayout(
      title: "VEHICLE",
      subtitle: plate,
      showLeftAvatar: false,
      leftAvatarText: "Car",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // VEHICLE HEADER CARD
          Container(
            padding: EdgeInsets.all(hp),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top: Plate + Status + Model + Type
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      plate,
                      style: GoogleFonts.inter(
                        fontSize: fs + 6,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.inter(
                          fontSize: fs - 2,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: _loadingDetails
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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.memory,
                      size: fs + 2,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      model,
                      style: GoogleFonts.inter(
                        fontSize: fs + 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Icon(
                      Icons.local_shipping,
                      size: fs + 2,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      type,
                      style: GoogleFonts.inter(
                        fontSize: fs + 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Bottom info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _infoItem(
                      "Last Seen",
                      lastSeen,
                      Icons.access_time,
                      colorScheme,
                    ),
                    _infoItem("Speed", speed, Icons.speed, colorScheme),
                    _infoItem(
                      "Ignition",
                      ignition,
                      Icons.electric_bolt,
                      colorScheme,
                    ),
                    _infoItem(
                      "Location",
                      location,
                      Icons.location_on,
                      colorScheme,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // TABS
          NavigateBox(
            selectedTab: selectedTab,
            tabs: tabs,
            onTabSelected: (tab) => setState(() => selectedTab = tab),
          ),
          const SizedBox(height: 24),

          // TAB CONTENT
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildTabContent(key: ValueKey(selectedTab)),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _infoItem(
    String label,
    String value,
    IconData icon,
    ColorScheme scheme,
  ) {
    final double width = MediaQuery.of(context).size.width;
    final double fs = AdaptiveUtils.getTitleFontSize(width);

    return Column(
      children: [
        Icon(icon, size: fs + 4, color: scheme.primary),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: fs - 4,
            color: scheme.onSurface.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: fs - 1,
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent({Key? key}) {
    Widget content;
    final imei = _details?.imei;

    switch (selectedTab) {
      case "Vehicle Details":
        content = VehicleDetailsTab(vehicleId: widget.id);
        break;
      case "Vehicle Users":
        content = VehicleUsersTab(users: _details?.users);
        break;
      case "Send Commands":
        content = SendCommandsTab(
          imei: imei,
          vehiclePlate: _details?.plate.isNotEmpty == true
              ? _details!.plate
              : "DL01 AB 1287",
          vehicleModel: _details?.model.isNotEmpty == true
              ? _details!.model
              : "GT06",
        );
        break;
      case "Logs":
        content = VehicleLogsTab(imei: imei, fallbackVehicleId: widget.id);
        break;
      case "Maps":
        content = VehicleMapTab(
          imei: imei,
          fallbackLocation: const LatLng(19.0760, 72.8777),
          vehiclePlate: _details?.plate.isNotEmpty == true
              ? _details!.plate
              : "DL01 AB 1287",
        );
        break;
      case "Documents":
        content = VehicleDocumentsTab(
          documents: _details?.documents,
          loading: _loadingDetails,
        );
        break;
      case "Vehicle Config":
        content = VehicleConfigTab(
          vehicleId: widget.id,
          initialConfigRaw: _details?.data,
        );
        break;
      default:
        content = const SizedBox.shrink();
    }

    // Now just return content directly — no special Expanded logic needed
    return Container(key: key, child: content);
  }
}
