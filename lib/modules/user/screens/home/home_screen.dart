import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/user_fleet_status_summary.dart';
import 'package:fleet_stack/core/models/user_recent_alert_item.dart';
import 'package:fleet_stack/core/models/user_top_asset_item.dart';
import 'package:fleet_stack/core/models/user_usage_last_7_days.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_home_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/main.dart';
import 'package:fleet_stack/modules/admin/theme/app_theme.dart';
import 'package:fleet_stack/modules/user/layout/app_layout.dart';
import 'package:fleet_stack/modules/user/widgets/home/card/fleet_card.dart';
import 'package:fleet_stack/modules/user/widgets/home/card/recent_activity_box.dart';
import 'package:fleet_stack/modules/user/widgets/home/card/search_bar.dart';
import 'package:fleet_stack/modules/user/widgets/home/card/top_customers_box.dart';
import 'package:fleet_stack/modules/user/widgets/home/card/vehicle_status_box.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // FleetStack-API-Reference.md confirmed User Home endpoints:
  // - GET /user/dashboard/fleet-status
  // - GET /user/dashboard/usage-last-7-days
  // - GET /user/dashboard/recent-alerts
  // - GET /user/dashboard/top-performing-assets

  String _selectedLanguage = 'EN';
  String _overviewMode = 'Fleet';

  ApiClient? _api;
  UserHomeRepository? _repo;
  CancelToken? _loadToken;

  bool _loading = false;
  bool _errorShown = false;

  UserFleetStatusSummary? _fleetStatus;
  UserUsageLast7Days? _usageLast7Days;
  List<UserRecentAlertItem>? _recentAlerts;
  List<UserTopAssetItem>? _topAssets;

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  @override
  void dispose() {
    _loadToken?.cancel('User home disposed');
    super.dispose();
  }

  UserHomeRepository _repoOrCreate() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= UserHomeRepository(api: _api!);
    return _repo!;
  }

  Future<void> _loadHome() async {
    _loadToken?.cancel('Reload user home');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    UserFleetStatusSummary? nextFleet = _fleetStatus;
    UserUsageLast7Days? nextUsage = _usageLast7Days;
    List<UserRecentAlertItem>? nextAlerts = _recentAlerts;
    List<UserTopAssetItem>? nextTopAssets = _topAssets;

    bool hasFailure = false;
    String? errorMessage;

    void captureFailure(Object error, String fallback) {
      if (error is ApiException &&
          error.message.trim() == 'Request cancelled') {
        return;
      }
      hasFailure = true;
      if (errorMessage == null || errorMessage!.trim().isEmpty) {
        if (error is ApiException && error.message.trim().isNotEmpty) {
          errorMessage = error.message;
        } else {
          errorMessage = fallback;
        }
      }
    }

    final repo = _repoOrCreate();

    final fleetRes = await repo.getFleetStatus(cancelToken: token);
    if (!mounted || token.isCancelled) return;
    fleetRes.when(
      success: (data) => nextFleet = data,
      failure: (error) => captureFailure(error, "Couldn't load fleet status."),
    );

    final usageRes = await repo.getUsageLast7Days(cancelToken: token);
    if (!mounted || token.isCancelled) return;
    usageRes.when(
      success: (data) => nextUsage = data,
      failure: (error) => captureFailure(error, "Couldn't load usage summary."),
    );

    final alertsRes = await repo.getRecentAlerts(cancelToken: token);
    if (!mounted || token.isCancelled) return;
    alertsRes.when(
      success: (data) => nextAlerts = data,
      failure: (error) => captureFailure(error, "Couldn't load recent alerts."),
    );

    final topAssetsRes = await repo.getTopPerformingAssets(cancelToken: token);
    if (!mounted || token.isCancelled) return;
    topAssetsRes.when(
      success: (data) => nextTopAssets = data,
      failure: (error) =>
          captureFailure(error, "Couldn't load top performing assets."),
    );

    if (!mounted) return;
    setState(() {
      _fleetStatus = nextFleet;
      _usageLast7Days = nextUsage;
      _recentAlerts = nextAlerts;
      _topAssets = nextTopAssets;
      _loading = false;
      if (!hasFailure) {
        _errorShown = false;
      }
    });

    if (!hasFailure || _errorShown || !mounted) return;
    _errorShown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage ?? "Couldn't load dashboard.")),
    );
  }

  Future<void> _showLanguagePicker(BuildContext context) async {
    final chosen = await showGeneralDialog<String?>(
      context: context,
      barrierLabel: 'Language',
      barrierDismissible: true,
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final theme = Theme.of(context);
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
                            _languageTile(ctx, 'EN', 'English', '🇬🇧'),
                            _languageTile(ctx, 'FR', 'Français', '🇫🇷'),
                            _languageTile(ctx, 'ES', 'Español', '🇪🇸'),
                            const SizedBox(height: 8),
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

    if (chosen == null || chosen == _selectedLanguage || !mounted) return;
    setState(() => _selectedLanguage = chosen);
    debugPrint('Language changed to: $chosen');
  }

  Widget _languageTile(
    BuildContext ctx,
    String code,
    String label,
    String flag,
  ) {
    final theme = Theme.of(ctx);
    final selected = code == _selectedLanguage;

    return InkWell(
      onTap: () => Navigator.of(ctx).pop(code),
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
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
      title: 'FLEET STACK',
      subtitle: 'Overview',
      actionIcons: [Icons.language, themeIcon, CupertinoIcons.bell],
      onActionTaps: [
        () => _showLanguagePicker(context),
        () {
          final isCurrentlyDark =
              Theme.of(context).brightness == Brightness.dark;
          final newDarkMode = !isCurrentlyDark;

          themeController.setDarkMode(newDarkMode);
          AppTheme.setDarkMode(newDarkMode);

          if (AppTheme.brandColor == AppTheme.defaultBrand ||
              AppTheme.brandColor == AppTheme.defaultDarkBrand) {
            final forcedBrand = newDarkMode
                ? AppTheme.defaultDarkBrand
                : AppTheme.defaultBrand;
            themeController.setBrand(forcedBrand);
            AppTheme.setBrand(forcedBrand);
          }
        },
        () => context.push('/user/notifications'),
      ],
      leftAvatarText: 'FS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSearchBar(),
          const SizedBox(height: 12),
          const SizedBox(height: 24),
          OverviewBox(
            mode: _overviewMode,
            onModeChanged: (newMode) {
              if (!mounted) return;
              setState(() => _overviewMode = newMode);
            },
            loading: _loading,
            fleetStatus: _fleetStatus,
            usage: _usageLast7Days,
            alertCount: _recentAlerts?.length,
          ),
          const SizedBox(height: 24),
          if (_overviewMode == 'Fleet') ...[
            VehicleStatusBox(loading: _loading, summary: _fleetStatus),
            const SizedBox(height: 24),
          ],
          if (_overviewMode == 'Fleet')
            RecentActivityBox(
              loading: _loading,
              items: _recentAlerts ?? const <UserRecentAlertItem>[],
            )
          else
            TopCustomersBox(
              loading: _loading,
              items: _topAssets ?? const <UserTopAssetItem>[],
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
