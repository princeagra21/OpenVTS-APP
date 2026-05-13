import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/user/di/user_notification_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:open_vts/features/user/domain/entities/user_notification_preferences.dart';
import 'package:open_vts/core/router/route_names.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:open_vts/features/user/presentation/components/appbars/user_home_appbar.dart';
import 'package:open_vts/features/user/presentation/screens/notification/push_notification/controller.dart';
import 'package:open_vts/features/user/presentation/screens/notification/push_notification/models.dart';
import 'package:open_vts/features/user/presentation/screens/notification/push_notification/widgets/channel_section.dart';
import 'package:open_vts/features/user/presentation/screens/notification/push_notification/widgets/navigation_box.dart';
import 'package:open_vts/features/user/presentation/screens/notification/push_notification/widgets/status_cards.dart';
import 'package:open_vts/features/user/presentation/screens/notification/push_notification/widgets/vehicle_cards.dart';
import 'package:open_vts/features/user/presentation/screens/notification/push_notification/widgets/vehicle_section.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class PushNotificationScreen extends ConsumerStatefulWidget {
  const PushNotificationScreen({super.key});

  @override
  ConsumerState<PushNotificationScreen> createState() => _PushNotificationScreenState();
}

class _PushNotificationScreenState extends ConsumerState<PushNotificationScreen> {
  late final PushNotificationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PushNotificationController(
      repository: ref.read(pushNotificationAdapterProvider),
    )..addListener(_onControllerChanged);

    _loadSettings();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      updateLocalUiState(this, () {});
    }
  }

  Future<void> _loadSettings() async {
    final result = await _controller.loadSettings();
    _showActionResult(result);
  }

  void _showActionResult(PushNotificationActionResult? result) {
    if (!mounted || result == null || result.message.trim().isEmpty) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _toggleChannel({
    required UserNotificationPreferenceItem item,
    required String key,
    required String label,
    bool? mobile,
    bool? whatsapp,
    bool? email,
  }) async {
    final result = await _controller.toggleChannel(
      item: item,
      key: key,
      label: label,
      mobile: mobile,
      whatsapp: whatsapp,
      email: email,
    );
    _showActionResult(result);
  }

  Future<void> _toggleBasicRule({
    required UserNotificationVehicle vehicle,
    bool? ignition,
    bool? alarm,
  }) async {
    final result = await _controller.toggleBasicRule(
      vehicle: vehicle,
      ignition: ignition,
      alarm: alarm,
    );
    _showActionResult(result);
  }

  Future<void> _toggleGeofenceRule({
    required UserNotificationVehicle vehicle,
    required bool enabled,
  }) async {
    final result = await _controller.toggleGeofenceRule(
      vehicle: vehicle,
      enabled: enabled,
    );
    _showActionResult(result);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(width);
    final topPadding = MediaQuery.of(context).padding.top;

    final vehicles = _controller.filteredVehiclesForSelectedTab();
    final preference = _controller.preferenceForSelectedTab();
    final spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final scale = (width / 420).clamp(0.9, 1.0);
    final mainFontSize = 14 * scale;
    final secondaryFontSize = 12 * scale;
    final iconSize = AdaptiveUtils.getIconSize(width);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? OpenVtsColors.panelDark
          : OpenVtsColors.panelLight,
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                padding,
                topPadding + AppUtils.appBarHeightCustom + 10,
                padding,
                padding,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PushNotificationNavigationBox(
                      selectedTab: _controller.selectedTabLabel,
                      tabs: _controller.tabs,
                      onTabSelected: _controller.setSelectedTab,
                    ),
                    const SizedBox(height: 16),
                    if (_controller.loading)
                      PushNotificationLoadingList(width: width, padding: padding)
                    else if (!_controller.hasSettings || preference == null)
                      PushNotificationEmptyCard(
                        padding: padding,
                        colorScheme: colorScheme,
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PushNotificationChannelSection(
                            title: _controller.tabTitle,
                            preference: preference,
                            padding: padding,
                            onToggleMobile: () => _toggleChannel(
                              item: preference,
                              key: '${preference.eventType}:mobile',
                              label: 'Mobile Push',
                              mobile: !preference.notifyMobilePush,
                            ),
                            onToggleWhatsApp: () => _toggleChannel(
                              item: preference,
                              key: '${preference.eventType}:whatsapp',
                              label: 'WhatsApp',
                              whatsapp: !preference.notifyWhatsapp,
                            ),
                            onToggleEmail: () => _toggleChannel(
                              item: preference,
                              key: '${preference.eventType}:email',
                              label: 'Email',
                              email: !preference.notifyEmail,
                            ),
                          ),
                          if (_controller.selectedTabLabel.toLowerCase() ==
                              'basic') ...[
                            const SizedBox(height: 16),
                            PushNotificationVehicleSection(
                              padding: padding,
                              spacing: spacing,
                              iconSize: iconSize,
                              mainFontSize: mainFontSize,
                              secondaryFontSize: secondaryFontSize,
                              searchController:
                                  _controller.vehicleSearchController,
                              onSearchChanged: (_) =>
                                  _controller.onVehicleQueryChanged(),
                              vehicleFilter: _controller.vehicleFilter,
                              onFilterChanged: _controller.setVehicleFilter,
                              vehiclePageSize: _controller.vehiclePageSize,
                              onPageSizeChanged: _controller.setVehiclePageSize,
                              onRefresh: _loadSettings,
                              child: _buildBasicVehicles(
                                vehicles,
                                colorScheme,
                                secondaryFontSize,
                              ),
                            ),
                          ],
                          if (_controller.selectedTabLabel.toLowerCase() ==
                              'overspeed') ...[
                            const SizedBox(height: 16),
                            PushNotificationVehicleSection(
                              padding: padding,
                              spacing: spacing,
                              iconSize: iconSize,
                              mainFontSize: mainFontSize,
                              secondaryFontSize: secondaryFontSize,
                              searchController:
                                  _controller.vehicleSearchController,
                              onSearchChanged: (_) =>
                                  _controller.onVehicleQueryChanged(),
                              vehicleFilter: _controller.vehicleFilter,
                              onFilterChanged: _controller.setVehicleFilter,
                              vehiclePageSize: _controller.vehiclePageSize,
                              onPageSizeChanged: _controller.setVehiclePageSize,
                              onRefresh: _loadSettings,
                              child: _buildOverspeedVehicles(
                                vehicles,
                                colorScheme,
                                secondaryFontSize,
                              ),
                            ),
                          ],
                          if (_controller.selectedTabLabel.toLowerCase() ==
                              'geofence') ...[
                            const SizedBox(height: 16),
                            PushNotificationVehicleSection(
                              padding: padding,
                              spacing: spacing,
                              iconSize: iconSize,
                              mainFontSize: mainFontSize,
                              secondaryFontSize: secondaryFontSize,
                              searchController:
                                  _controller.vehicleSearchController,
                              onSearchChanged: (_) =>
                                  _controller.onVehicleQueryChanged(),
                              vehicleFilter: _controller.vehicleFilter,
                              onFilterChanged: _controller.setVehicleFilter,
                              vehiclePageSize: _controller.vehiclePageSize,
                              onPageSizeChanged: _controller.setVehiclePageSize,
                              onRefresh: _loadSettings,
                              child: _buildGeofenceVehicles(
                                vehicles,
                                colorScheme,
                                secondaryFontSize,
                              ),
                            ),
                          ],
                        ],
                      ),
                    SizedBox(height: padding),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: padding,
            right: padding,
            top: 0,
            child: Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? OpenVtsColors.panelDark
                  : OpenVtsColors.panelLight,
              child: UserHomeAppBar(
                title: 'Notifications',
                leadingIcon: Icons.notifications_outlined,
                onClose: () => context.go(AppRoutePaths.userHome),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicVehicles(
    List<UserNotificationVehicle> vehicles,
    ColorScheme colorScheme,
    double secondaryFontSize,
  ) {
    if (vehicles.isEmpty) {
      return _emptyVehiclesText(colorScheme, secondaryFontSize);
    }

    return Column(
      children: vehicles.map((vehicle) {
        final rule = _controller.basicRuleFor(vehicle.id.toString());
        final ignitionEnabled = rule?.ignitionEnabled ?? false;
        final alarmEnabled = rule?.alarmEnabled ?? false;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PushNotificationVehicleAlertCard(
            vehicle: vehicle,
            ignitionEnabled: ignitionEnabled,
            alarmEnabled: alarmEnabled,
            onIgnitionTap: () => _toggleBasicRule(
              vehicle: vehicle,
              ignition: !ignitionEnabled,
            ),
            onAlarmTap: () => _toggleBasicRule(
              vehicle: vehicle,
              alarm: !alarmEnabled,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOverspeedVehicles(
    List<UserNotificationVehicle> vehicles,
    ColorScheme colorScheme,
    double secondaryFontSize,
  ) {
    if (vehicles.isEmpty) {
      return _emptyVehiclesText(colorScheme, secondaryFontSize);
    }

    return Column(
      children: vehicles.map((vehicle) {
        final rule = _controller.overspeedRuleFor(vehicle.id.toString());
        final enabled = rule?.enabled ?? false;
        final speed = rule?.speedLimitKph;
        final speedController =
            _controller.speedControllerFor(vehicle.id.toString(), speed);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PushNotificationVehicleSpeedFormCard(
            vehicle: vehicle,
            enabled: enabled,
            controller: speedController,
            onToggle: () => _controller.updateOverspeedRule(
              vehicle: vehicle,
              enabled: !enabled,
            ),
            onSubmit: (value) {
              final parsed = int.tryParse(value.trim());
              _controller.updateOverspeedRule(
                vehicle: vehicle,
                speedLimit: parsed,
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGeofenceVehicles(
    List<UserNotificationVehicle> vehicles,
    ColorScheme colorScheme,
    double secondaryFontSize,
  ) {
    if (vehicles.isEmpty) {
      return _emptyVehiclesText(colorScheme, secondaryFontSize);
    }

    return Column(
      children: vehicles.map((vehicle) {
        final enabled = _controller.geofenceEnabledFor(vehicle.id.toString());
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PushNotificationVehicleGeofenceCard(
            vehicle: vehicle,
            enabled: enabled,
            onToggle: () => _toggleGeofenceRule(
              vehicle: vehicle,
              enabled: !enabled,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _emptyVehiclesText(ColorScheme colorScheme, double secondaryFontSize) {
    return Text(
      'No vehicles found',
      style: AppFonts.roboto(
        fontSize: secondaryFontSize,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }
}


