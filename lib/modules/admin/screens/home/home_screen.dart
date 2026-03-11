// lib/screens/home/home_screen.dart
// -----------------------------
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_dashboard_summary.dart';
import 'package:fleet_stack/core/models/admin_vehicle_preview_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_dashboard_repository.dart';
import 'package:fleet_stack/core/repositories/admin_vehicle_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/main.dart';
import 'package:fleet_stack/modules/admin/components/card/actions_buttons.dart';
import 'package:fleet_stack/modules/admin/components/card/fleet_card.dart';
import 'package:fleet_stack/modules/admin/components/card/recent_activity_box.dart';
import 'package:fleet_stack/modules/admin/components/card/search_bar.dart';
import 'package:fleet_stack/modules/admin/components/card/vehicle_status_box.dart';
import 'package:fleet_stack/modules/admin/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../layout/app_layout.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedLanguage = 'EN';
  AdminDashboardSummary? _summary;
  List<AdminVehiclePreviewItem>? _vehiclePreview;
  bool _loading = false;
  bool _loadingVehiclesPreview = false;
  bool _errorShown = false;
  bool _vehiclesErrorShown = false;
  CancelToken? _token;
  CancelToken? _vehiclesToken;

  ApiClient? _api;
  AdminDashboardRepository? _repo;
  AdminVehicleRepository? _vehicleRepo;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadVehiclePreview();
  }

  @override
  void dispose() {
    _token?.cancel('Admin home disposed');
    _vehiclesToken?.cancel('Admin home disposed');
    super.dispose();
  }

  /// Confirmed API source (FleetStack-API-Reference.md):
  /// - GET /admin/dashboard/summary?rk=0[&currency=INR]
  /// Keys used:
  /// - totals.totalVehicles
  /// - totals.totalUsers
  /// - expiry.thisMonth
  /// - expired / expiredCount (if present)
  /// - vehicleLiveStatus.running/stop/inactive/noData
  Future<void> _loadSummary() async {
    _token?.cancel('Reload dashboard summary');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= AdminDashboardRepository(api: _api!);

      final res = await _repo!.getAdminDashboardSummary(cancelToken: token);
      if (!mounted) return;

      res.when(
        success: (data) {
          if (kDebugMode) {
            debugPrint(
              '[Admin Home] GET /admin/dashboard/summary status=2xx '
              'vehicles=${data.totalVehicles} users=${data.totalUsers} '
              'expiring30d=${data.expiring30d} expired=${data.expired} '
              'running=${data.running} stop=${data.stop} '
              'notWorking=${data.notWorking48h} noData=${data.noData}',
            );
          }

          if (!mounted) return;
          setState(() {
            _summary = data;
            _loading = false;
            _errorShown = false;
          });
        },
        failure: (error) {
          if (kDebugMode) {
            final status = error is ApiException ? error.statusCode : null;
            debugPrint(
              '[Admin Home] GET /admin/dashboard/summary status=${status ?? 'error'}',
            );
          }

          if (!mounted) return;
          setState(() {
            _summary = null;
            _loading = false;
          });

          if (_errorShown) return;
          _errorShown = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't load dashboard summary.")),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _summary = null;
        _loading = false;
      });
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load dashboard summary.")),
      );
    }
  }

  Future<void> _loadVehiclePreview() async {
    _vehiclesToken?.cancel('Reload vehicle preview');
    final token = CancelToken();
    _vehiclesToken = token;

    if (!mounted) return;
    setState(() => _loadingVehiclesPreview = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _vehicleRepo ??= AdminVehicleRepository(api: _api!);

      final listRes = await _vehicleRepo!.getVehiclePreviewList(
        limit: 5,
        cancelToken: token,
      );
      if (!mounted) return;

      await listRes.when(
        success: (items) async {
          var merged = items;

          if (items.isNotEmpty) {
            final ids = items
                .map((e) => e.id.trim())
                .where((e) => e.isNotEmpty)
                .toList();
            final imeis = items
                .map((e) => e.imei.trim())
                .where((e) => e.isNotEmpty)
                .toList();

            final liveRes = await _vehicleRepo!.getVehicleLiveStatus(
              vehicleIds: ids,
              imeis: imeis,
              cancelToken: token,
            );

            merged = liveRes.when(
              success: (statusMap) {
                return items.map((item) {
                  final byId = statusMap[item.id.trim()];
                  final byImei = statusMap[item.imei.trim()];
                  return item.withLiveStatus(byId ?? byImei);
                }).toList();
              },
              failure: (_) => items,
            );
          }

          if (kDebugMode) {
            debugPrint(
              '[Admin Home] GET /admin/vehicles + /admin/map-telemetry '
              'status=2xx count=${merged.length}',
            );
          }

          if (!mounted) return;
          setState(() {
            _vehiclePreview = merged;
            _loadingVehiclesPreview = false;
            _vehiclesErrorShown = false;
          });
        },
        failure: (error) async {
          if (kDebugMode) {
            final status = error is ApiException ? error.statusCode : null;
            debugPrint(
              '[Admin Home] GET /admin/vehicles status=${status ?? 'error'}',
            );
          }

          if (!mounted) return;
          setState(() {
            _vehiclePreview = null;
            _loadingVehiclesPreview = false;
          });

          if (_vehiclesErrorShown) return;
          _vehiclesErrorShown = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't load vehicles preview.")),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _vehiclePreview = null;
        _loadingVehiclesPreview = false;
      });
      if (_vehiclesErrorShown) return;
      _vehiclesErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load vehicles preview.")),
      );
    }
  }

  /// Stylish popup (top-right card). Uses showGeneralDialog for custom animation.
  Future<void> _showLanguagePicker(BuildContext context) async {
    final chosen = await showGeneralDialog<String?>(
      context: context,
      barrierLabel: "Language",
      barrierDismissible: true,
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) {
        // pageBuilder must return something — actual UI is in transitionBuilder
        return const SizedBox.shrink();
      },
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final theme = Theme.of(context);
        // Position the popup near the top-right .
        return SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 72.0, right: 14.0),
              child: FadeTransition(
                opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.97, end: 1.0).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                  ),
                  child: Material(
                    color: theme.colorScheme.surface,
                    elevation: 18,
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 220,
                        maxWidth: 260,
                      ),
                      child: IntrinsicWidth(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Language',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => Navigator.of(ctx).pop(),
                                    child: Container(
                                      height: 32,
                                      width: 32,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            // Options
                            _languageTile(ctx, 'EN', 'English', '🇬🇧'),
                            _languageTile(ctx, 'FR', 'Français', '🇫🇷'),
                            _languageTile(ctx, 'ES', 'Español', '🇪🇸'),
                            const SizedBox(height: 8),
                            // Optional footer / small caption
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Text(
                                'App language will update after selection.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (chosen != null && chosen != _selectedLanguage) {
      setState(() {
        _selectedLanguage = chosen;
      });
      // TODO: Hook into your localization provider here.
      debugPrint('Language changed to: $chosen');
    }
  }

  Widget _languageTile(
    BuildContext ctx,
    String code,
    String label,
    String flag,
  ) {
    final theme = Theme.of(ctx);
    final bool selected = code == _selectedLanguage;

    return InkWell(
      onTap: () => Navigator.of(ctx).pop(code),
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // flag circle
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: theme.colorScheme.primary.withOpacity(0.06),
              ),
              alignment: Alignment.center,
              child: Text(flag, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    code,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: 16,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final themeIcon = isDark ? Icons.light_mode : Icons.dark_mode;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "Overview",
      // action icons: language, theme toggle, notifications
      actionIcons: [Icons.language, themeIcon, CupertinoIcons.bell],

      // onActionTaps must map 1:1 with actionIcons order
      onActionTaps: [
        // Language tap -> stylish popup
        () => _showLanguagePicker(context),

        // Theme tap -> toggle light/dark immediately (non-blocking)
        () {
          final isCurrentlyDark =
              Theme.of(context).brightness == Brightness.dark;
          final newDarkMode = !isCurrentlyDark;

          // update controller (instant UI update if your controller notifies listeners)
          themeController.setDarkMode(newDarkMode);

          // persist (non-blocking)
          AppTheme.setDarkMode(newDarkMode);

          // If using the Default brand, ensure brand matches mode
          if (AppTheme.brandColor == AppTheme.defaultBrand ||
              AppTheme.brandColor == AppTheme.defaultDarkBrand) {
            final forcedBrand = newDarkMode
                ? AppTheme.defaultDarkBrand
                : AppTheme.defaultBrand;
            themeController.setBrand(forcedBrand);
            AppTheme.setBrand(forcedBrand);
          }
        },

        // Notifications tap
        () => context.push('/admin/notifications'),
      ],

      leftAvatarText: 'FS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSearchBar(),
          const SizedBox(height: 12),
          const ActionsButtons(),
          const SizedBox(height: 24),
          FleetOverviewBox(summary: _summary, loading: _loading),
          const SizedBox(height: 24),
          VehicleStatusBox(summary: _summary, loading: _loading),
          const SizedBox(height: 24),
          RecentActivityBox(
            vehicles: _vehiclePreview,
            loading: _loadingVehiclesPreview,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
