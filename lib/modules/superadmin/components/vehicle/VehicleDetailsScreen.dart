// screens/vehicle/vehicle_details_screen.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/vehicle_details.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
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

  String safe(String? v) {
    if (v == null) return '-';
    final t = v.trim();
    return t.isEmpty ? '-' : t;
  }

  String _metaValue(List<String> keys) {
    final data = _details?.data;
    if (data == null) return '-';
    for (final key in keys) {
      final raw = data[key];
      final value = safe(raw?.toString());
      if (value != '-') return value;
    }
    return '-';
  }

  String _displayStatus() {
    final raw = safe(_details?.status);
    if (raw != '-') return raw;
    if (_details == null) return '-';
    return _details!.isActive ? 'Active' : 'Inactive';
  }

  String _displayPlate() {
    final plate = safe(_details?.plate);
    if (plate != '-') return plate;
    final name = safe(_details?.name);
    if (name != '-') return name;
    return 'Vehicle ${widget.id}';
  }

  String _displayMetric(String? value, {String? suffix}) {
    final clean = safe(value);
    if (clean == '-') return '-';
    if (suffix == null || clean.toLowerCase().contains(suffix.toLowerCase())) {
      return clean;
    }
    return '$clean $suffix';
  }

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
              : "Couldn't load vehicle.";
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't load vehicle.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double fs = AdaptiveUtils.getTitleFontSize(width);

    final plate = _displayPlate();
    final status = _displayStatus();
    final model = safe(_details?.model);
    final type = safe(_details?.type);
    final metaId = safe(
      _details?.id.isNotEmpty == true ? _details!.id : widget.id,
    );
    final metaImei = safe(_details?.imei);
    final metaSim = safe(_details?.simNumber);
    final metaPhone = _metaValue(const [
      'phoneNumber',
      'phone_number',
      'phone',
      'mobile',
      'msisdn',
      'contactNumber',
    ]);

    final lastSeen = safe(_details?.lastSeen);
    final speed = _displayMetric(_details?.speed, suffix: 'km/h');
    final ignition = safe(_details?.ignition);
    final location = safe(_details?.locationName);

    return AppLayout(
      title: _loadingDetails ? " " : "VEHICLE",
      subtitle: _loadingDetails ? " " : plate,
      showLeftAvatar: false,
      leftAvatarText: "Car",
      child: _loadingDetails
          ? _buildVehicleDetailsShimmer(
              colorScheme: colorScheme,
              hp: hp,
              fs: fs,
              width: width,
            )
          : Column(
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
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: (width * 0.58).clamp(140.0, 320.0),
                            ),
                            child: Text(
                              plate,
                              style: GoogleFonts.roboto(
                                fontSize: fs + 6,
                                fontWeight: FontWeight.w900,
                                color: colorScheme.onSurface,
                                letterSpacing: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: status.toLowerCase() == 'inactive'
                                  ? colorScheme.error
                                  : Colors.green.shade600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: (width * 0.34).clamp(90.0, 180.0),
                              ),
                              child: Text(
                                status,
                                style: GoogleFonts.roboto(
                                  fontSize: fs - 2,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 20,
                        runSpacing: 8,
                        children: [
                          _headerMetaItem(
                            icon: Icons.memory,
                            value: model,
                            scheme: colorScheme,
                            width: width,
                            fs: fs,
                          ),
                          _headerMetaItem(
                            icon: Icons.local_shipping,
                            value: type,
                            scheme: colorScheme,
                            width: width,
                            fs: fs,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _metaChip(
                            label: 'ID',
                            value: metaId,
                            scheme: colorScheme,
                            width: width,
                          ),
                          _metaChip(
                            label: 'IMEI',
                            value: metaImei,
                            scheme: colorScheme,
                            width: width,
                          ),
                          _metaChip(
                            label: 'SIM',
                            value: metaSim,
                            scheme: colorScheme,
                            width: width,
                          ),
                          if (metaPhone != '-')
                            _metaChip(
                              label: 'Phone',
                              value: metaPhone,
                              scheme: colorScheme,
                              width: width,
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

  Widget _buildVehicleDetailsShimmer({
    required ColorScheme colorScheme,
    required double hp,
    required double fs,
    required double width,
  }) {
    final double tabWidth = (width * 0.2).clamp(72.0, 112.0).toDouble();
    final double metricIcon = fs + 4;

    Widget metricSkeleton() {
      return Column(
        children: [
          AppShimmer(width: metricIcon, height: metricIcon, radius: metricIcon),
          const SizedBox(height: 6),
          AppShimmer(width: 58, height: fs - 2, radius: 8),
          const SizedBox(height: 4),
          AppShimmer(width: 78, height: fs, radius: 8),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header shimmer (title + plate line)
        Row(
          children: [
            AppShimmer(width: 32, height: 32, radius: 16),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer(width: width * 0.2, height: fs + 6, radius: 8),
                const SizedBox(height: 8),
                AppShimmer(width: width * 0.35, height: fs + 8, radius: 8),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Summary card shimmer
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppShimmer(width: width * 0.34, height: fs + 20, radius: 10),
                  const SizedBox(width: 16),
                  AppShimmer(width: 96, height: 34, radius: 12),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppShimmer(width: 96, height: fs + 6, radius: 8),
                  const SizedBox(width: 20),
                  AppShimmer(width: 110, height: fs + 6, radius: 8),
                ],
              ),
              const SizedBox(height: 16),
              AppShimmer(width: width * 0.72, height: fs + 4, radius: 8),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List<Widget>.generate(4, (_) => metricSkeleton()),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Tabs shimmer
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List<Widget>.generate(
            4,
            (_) => AppShimmer(width: tabWidth, height: 36, radius: 18),
          ),
        ),

        const SizedBox(height: 24),

        // Logs panel shimmer
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(hp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppShimmer(width: width * 0.25, height: fs + 10, radius: 8),
                    const SizedBox(width: 8),
                    AppShimmer(width: 12, height: 12, radius: 6),
                  ],
                ),
                const SizedBox(height: 8),
                AppShimmer(width: width * 0.5, height: fs, radius: 8),
                const SizedBox(height: 20),
                AppShimmer(width: double.infinity, height: 50, radius: 16),
                const SizedBox(height: 16),
                AppShimmer(width: double.infinity, height: 54, radius: 16),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: AppShimmer(
                        width: double.infinity,
                        height: 44,
                        radius: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppShimmer(
                        width: double.infinity,
                        height: 44,
                        radius: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AppShimmer(width: double.infinity, height: 180, radius: 16),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
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
          style: GoogleFonts.roboto(
            fontSize: fs - 4,
            color: scheme.onSurface.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: fs - 1,
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _metaChip({
    required String label,
    required String value,
    required ColorScheme scheme,
    required double width,
  }) {
    final fs = AdaptiveUtils.getTitleFontSize(width);
    final maxWidth = (width * 0.35).clamp(96.0, 180.0).toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.roboto(
              fontSize: fs - 3,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withOpacity(0.65),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: fs - 3,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerMetaItem({
    required IconData icon,
    required String value,
    required ColorScheme scheme,
    required double width,
    required double fs,
  }) {
    final maxWidth = (width * 0.32).clamp(80.0, 180.0).toDouble();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: fs + 2, color: scheme.primary),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Text(
            safe(value),
            style: GoogleFonts.roboto(
              fontSize: fs + 1,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent({Key? key}) {
    Widget content;
    final imei = _details?.imei;
    final plate = _displayPlate();
    final model = safe(_details?.model);

    switch (selectedTab) {
      case "Vehicle Details":
        content = VehicleDetailsTab(vehicleId: widget.id, details: _details);
        break;
      case "Vehicle Users":
        content = VehicleUsersTab(users: _details?.users);
        break;
      case "Send Commands":
        content = SendCommandsTab(
          imei: imei,
          vehiclePlate: plate,
          vehicleModel: model,
        );
        break;
      case "Logs":
        content = VehicleLogsTab(imei: imei, fallbackVehicleId: widget.id);
        break;
      case "Maps":
        content = VehicleMapTab(
          imei: imei,
          fallbackLocation: const LatLng(28.6139, 77.2090),
          vehiclePlate: plate,
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
