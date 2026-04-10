import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/user_notification_preferences.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_notification_preferences_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:fleet_stack/modules/user/components/appbars/user_home_appbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class PushNotificationScreen extends StatefulWidget {
  const PushNotificationScreen({super.key});

  @override
  State<PushNotificationScreen> createState() => _PushNotificationScreenState();
}

class _PushNotificationScreenState extends State<PushNotificationScreen> {
  final List<UserNotificationPreferenceItem> _items =
      <UserNotificationPreferenceItem>[];
  UserNotificationPreferences? _prefs;
  final TextEditingController _vehicleSearchController =
      TextEditingController();
  String _vehicleFilter = 'All';
  int _vehiclePageSize = 10;
  final Map<String, TextEditingController> _speedControllers =
      <String, TextEditingController>{};
  final Map<String, bool> _geofenceOverrides = <String, bool>{};

  bool _loading = false;
  bool _errorShown = false;
  final Set<String> _updating = <String>{};

  ApiClient? _api;
  UserNotificationPreferencesRepository? _repo;
  CancelToken? _token;

  String _selectedTab = 'Basic';
  final List<String> _tabs = const ['Basic', 'Overspeed', 'Geofence'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _token?.cancel('Push notifications disposed');
    _vehicleSearchController.dispose();
    for (final c in _speedControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  UserNotificationPreferencesRepository _repoOrCreate() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= UserNotificationPreferencesRepository(api: _api!);
    return _repo!;
  }

  Future<void> _loadSettings() async {
    _token?.cancel('Reload push notification settings');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final res = await _repoOrCreate().getPreferences(cancelToken: token);
      if (!mounted || token.isCancelled) return;

      res.when(
        success: (prefs) {
          setState(() {
            _prefs = prefs;
            _items
              ..clear()
              ..addAll(prefs.items);
            _loading = false;
            _errorShown = false;
          });
        },
        failure: (error) {
          setState(() {
            _items.clear();
            _loading = false;
          });
          if (_errorShown) return;
          _errorShown = true;
          var msg = "Couldn't load notification settings.";
          if (error is ApiException && error.message.trim().isNotEmpty) {
            msg = error.message;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items.clear();
        _loading = false;
      });
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load notification settings.")),
      );
    }
  }

  List<UserNotificationPreferenceItem> _filteredItems() {
    final tab = _selectedTab.toUpperCase();
    if (tab == 'BASIC') {
      return _items.where((e) => e.eventType == 'BASIC').toList();
    }
    if (tab == 'OVERSPEED') {
      return _items.where((e) => e.eventType == 'OVERSPEED').toList();
    }
    if (tab == 'GEOFENCE') {
      return _items.where((e) => e.eventType == 'GEOFENCE').toList();
    }
    return _items;
  }

  List<UserNotificationVehicle> _vehicles() {
    return _prefs?.vehicles ?? const <UserNotificationVehicle>[];
  }

  UserBasicAlertRule? _basicRuleFor(String vehicleId) {
    return _prefs?.basicRuleFor(vehicleId);
  }

  UserOverspeedRule? _overspeedRuleFor(String vehicleId) {
    return _prefs?.overspeedRuleFor(vehicleId);
  }

  bool _geofenceEnabledFor(String vehicleId) {
    final override = _geofenceOverrides[vehicleId];
    if (override != null) return override;
    final data = _prefs?.data ?? const <String, dynamic>{};
    final list = (data['geofenceMatrix'] is List)
        ? data['geofenceMatrix'] as List
        : (data['geofences'] is List ? data['geofences'] as List : const []);
    for (final item in list) {
      if (item is Map) {
        final vid = item['vehicleId']?.toString() ?? item['id']?.toString();
        if (vid == vehicleId) {
          final enabled = item['enabled'] ?? item['isEnabled'] ?? item['active'];
          if (enabled is bool) return enabled;
          if (enabled is num) return enabled != 0;
          if (enabled is String) {
            final v = enabled.toLowerCase();
            return v == 'true' || v == '1' || v == 'yes' || v == 'on';
          }
          return true;
        }
      }
    }
    return false;
  }

  TextEditingController _speedControllerFor(
    String vehicleId,
    int? speed,
  ) {
    final existing = _speedControllers[vehicleId];
    if (existing != null) return existing;
    final controller = TextEditingController(
      text: speed == null ? '' : speed.toString(),
    );
    _speedControllers[vehicleId] = controller;
    return controller;
  }

  UserNotificationPreferenceItem? _preferenceForTab() {
    final items = _filteredItems();
    if (items.isEmpty) return null;
    return items.first;
  }

  String _tabTitle() {
    final t = _selectedTab.toLowerCase();
    if (t == 'overspeed') return 'Over Speed';
    if (t == 'geofence') return 'Geofence';
    return 'Basic';
  }

  Future<void> _toggleChannel({
    required UserNotificationPreferenceItem item,
    required String key,
    required String label,
    bool? mobile,
    bool? whatsapp,
    bool? email,
  }) async {
    if (_updating.contains(key)) return;
    setState(() => _updating.add(key));

    final updated = item.copyWith(
      notifyMobilePush: mobile ?? item.notifyMobilePush,
      notifyWhatsapp: whatsapp ?? item.notifyWhatsapp,
      notifyEmail: email ?? item.notifyEmail,
    );
    final enabledNow = label == 'Mobile Push'
        ? updated.notifyMobilePush
        : label == 'WhatsApp'
            ? updated.notifyWhatsapp
            : updated.notifyEmail;

    final prevIndex =
        _items.indexWhere((e) => e.eventType == item.eventType);
    if (prevIndex != -1) {
      setState(() {
        _items[prevIndex] = updated;
      });
    }

    final res = await _repoOrCreate().updatePreference(updated);
    if (!mounted) return;

    res.when(
      success: (_) async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${item.eventType} • $label ${enabledNow ? 'enabled' : 'disabled'}',
            ),
          ),
        );
      },
      failure: (error) {
        if (prevIndex != -1) {
          setState(() {
            _items[prevIndex] = item;
          });
        }
        if (!_errorShown) {
          _errorShown = true;
          final msg =
              error is ApiException && error.message.trim().isNotEmpty
              ? error.message
              : "Couldn't update $label.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
      },
    );

    if (!mounted) return;
    setState(() => _updating.remove(key));
  }

  Future<void> _toggleBasicRule({
    required UserNotificationVehicle vehicle,
    bool? ignition,
    bool? alarm,
  }) async {
    final key = 'basic:${vehicle.id}';
    if (_updating.contains(key)) return;
    setState(() => _updating.add(key));

    final prefs = _prefs;
    if (prefs == null) {
      setState(() => _updating.remove(key));
      return;
    }

    final current = prefs.basicRuleFor(vehicle.id.toString());
    final baseRule = current ??
        UserBasicAlertRule(<String, dynamic>{
          'vehicleId': vehicle.id,
          'ignitionEnabled': false,
          'alarmEnabled': false,
        });
    final nextRule = baseRule.copyWith(
          ignitionEnabled: ignition ?? current?.ignitionEnabled ?? false,
          alarmEnabled: alarm ?? current?.alarmEnabled ?? false,
        );

    final updatedRules = [
      ...prefs.basicRules.where((r) => r.vehicleId != vehicle.id.toString()),
      nextRule,
    ];

    final nextPrefs = prefs.copyWith(basicRules: updatedRules);
    setState(() => _prefs = nextPrefs);

    final res = await _repoOrCreate().updatePreferencesPayload(
      nextPrefs.toUpdatePayload(),
    );

    if (!mounted) return;
    res.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${vehicle.name} • Basic alerts updated',
            ),
          ),
        );
      },
      failure: (error) {
        setState(() => _prefs = prefs);
        if (!_errorShown) {
          _errorShown = true;
          final msg =
              error is ApiException && error.message.trim().isNotEmpty
              ? error.message
              : "Couldn't update basic alerts.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
      },
    );

    if (!mounted) return;
    setState(() => _updating.remove(key));
  }

  Future<void> _updateOverspeedRule({
    required UserNotificationVehicle vehicle,
    required int? speedLimit,
  }) async {
    final key = 'overspeed:${vehicle.id}';
    if (_updating.contains(key)) return;
    setState(() => _updating.add(key));

    final prefs = _prefs;
    if (prefs == null) {
      setState(() => _updating.remove(key));
      return;
    }

    final current = prefs.overspeedRuleFor(vehicle.id.toString());
    final enabled = speedLimit != null && speedLimit > 0;
    final nextRule = (current ??
            UserOverspeedRule(<String, dynamic>{
              'vehicleId': vehicle.id,
              'enabled': enabled,
              'speedLimitKph': speedLimit,
            }))
        .copyWith(
          enabled: enabled,
          speedLimitKph: speedLimit,
        );

    final updatedRules = [
      ...prefs.overspeedRules
          .where((r) => r.vehicleId != vehicle.id.toString()),
      nextRule,
    ];

    final nextPrefs = prefs.copyWith(overspeedRules: updatedRules);
    setState(() => _prefs = nextPrefs);

    final res = await _repoOrCreate().updatePreferencesPayload(
      nextPrefs.toUpdatePayload(),
    );

    if (!mounted) return;
    res.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${vehicle.name} • Speed limit updated',
            ),
          ),
        );
      },
      failure: (error) {
        setState(() => _prefs = prefs);
        if (!_errorShown) {
          _errorShown = true;
          final msg =
              error is ApiException && error.message.trim().isNotEmpty
              ? error.message
              : "Couldn't update speed limit.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
      },
    );

    if (!mounted) return;
    setState(() => _updating.remove(key));
  }

  Future<void> _toggleGeofenceRule({
    required UserNotificationVehicle vehicle,
    required bool enabled,
  }) async {
    final key = 'geofence:${vehicle.id}';
    if (_updating.contains(key)) return;
    setState(() {
      _updating.add(key);
      _geofenceOverrides[vehicle.id.toString()] = enabled;
    });

    final prefs = _prefs;
    if (prefs == null) {
      setState(() => _updating.remove(key));
      return;
    }

    final data = Map<String, dynamic>.from(prefs.data);
    final matrix = <Map<String, dynamic>>[];
    final existing = data['geofenceMatrix'];
    if (existing is List) {
      for (final item in existing) {
        if (item is Map) {
          matrix.add(Map<String, dynamic>.from(item.cast()));
        }
      }
    }
    final vid = vehicle.id.toString();
    final idx = matrix.indexWhere(
      (e) => e['vehicleId']?.toString() == vid || e['id']?.toString() == vid,
    );
    final nextItem = <String, dynamic>{
      'vehicleId': int.tryParse(vid) ?? vid,
      'enabled': enabled,
      'zone': 'Test Zone',
    };
    if (idx >= 0) {
      matrix[idx] = nextItem;
    } else {
      matrix.add(nextItem);
    }
    data['geofenceMatrix'] = matrix;

    final payload = prefs.toUpdatePayload();
    payload['geofenceMatrix'] = matrix;

    final res = await _repoOrCreate().updatePreferencesPayload(payload);

    if (!mounted) return;
    res.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${vehicle.name} • Test Zone ${enabled ? 'enabled' : 'disabled'}',
            ),
          ),
        );
      },
      failure: (error) {
        if (!_errorShown) {
          _errorShown = true;
          final msg =
              error is ApiException && error.message.trim().isNotEmpty
              ? error.message
              : "Couldn't update geofence.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
      },
    );

    if (!mounted) return;
    setState(() => _updating.remove(key));
  }

  Widget _buildItemsBlock({
    required BuildContext context,
    required List<UserNotificationPreferenceItem> items,
    required double width,
    required double hp,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        crossAxisSpacing: hp,
        mainAxisSpacing: 12,
        childAspectRatio: 4.5,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _MoreMenuCard(
          title: item.label,
          subtitle: item.subtitle,
          icon: CupertinoIcons.bell,
          route: '/user/toggle/${Uri.encodeComponent(item.eventType)}',
          width: width,
          hp: hp,
          isListMode: true,
        );
      },
    );
  }

  Widget _buildLoadingBlock({required double width, required double hp}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        crossAxisSpacing: hp,
        mainAxisSpacing: 12,
        childAspectRatio: 4.5,
      ),
      itemBuilder: (context, index) =>
          _LoadingCard(width: width, hp: hp, isListMode: true),
    );
  }

  Widget _buildEmptyCard({
    required double hp,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hp * 1.2, vertical: hp),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No notification settings found',
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enable channels from the backend to manage alert delivery here.',
            style: GoogleFonts.roboto(
              color: colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(width);
    final double topPadding = MediaQuery.of(context).padding.top;

    final items = _filteredItems();
    final pref = _preferenceForTab();
    final vehicles = _vehicles();
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double fsSection = 18 * scale;
    final double fsMain = 14 * scale;
    final double fsSecondary = 12 * scale;
    final double iconSize = AdaptiveUtils.getIconSize(width);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F7),
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
                    _NavigateBox(
                      selectedTab: _selectedTab,
                      tabs: _tabs,
                      onTabSelected: (next) {
                        setState(() => _selectedTab = next);
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_loading)
                      _buildLoadingBlock(width: width, hp: padding)
                    else if (items.isEmpty || pref == null)
                      _buildEmptyCard(hp: padding, colorScheme: colorScheme)
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(padding),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.onSurface.withOpacity(0.08),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _tabTitle(),
                                  style: GoogleFonts.roboto(
                                    fontSize:
                                        AdaptiveUtils.getSubtitleFontSize(width),
                                    height: 24 / 18,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _channelRow(
                                  context,
                                  label: 'Mobile Push',
                                  icon: Icons.notifications_active_outlined,
                                  enabled: pref.notifyMobilePush,
                                  onTap: () => _toggleChannel(
                                    item: pref,
                                    key: '${pref.eventType}:mobile',
                                    label: 'Mobile Push',
                                    mobile: !pref.notifyMobilePush,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _channelRow(
                                  context,
                                  label: 'WhatsApp',
                                  icon: Icons.chat_bubble_outline,
                                  enabled: pref.notifyWhatsapp,
                                  onTap: () => _toggleChannel(
                                    item: pref,
                                    key: '${pref.eventType}:whatsapp',
                                    label: 'WhatsApp',
                                    whatsapp: !pref.notifyWhatsapp,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _channelRow(
                                  context,
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                  enabled: pref.notifyEmail,
                                  onTap: () => _toggleChannel(
                                    item: pref,
                                    key: '${pref.eventType}:email',
                                    label: 'Email',
                                    email: !pref.notifyEmail,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedTab.toLowerCase() == 'basic') ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(padding),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.onSurface.withOpacity(0.08),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Vehicles',
                                    style: GoogleFonts.roboto(
                                      fontSize: fsSection,
                                      height: 24 / 18,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  SizedBox(height: padding),
                                  // Search
                                  Container(
                                    height: padding * 3.5,
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color:
                                            colorScheme.onSurface.withOpacity(0.1),
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _vehicleSearchController,
                                      onChanged: (_) => setState(() {}),
                                      style: GoogleFonts.roboto(
                                        fontSize: fsMain,
                                        height: 20 / 14,
                                        color: colorScheme.onSurface,
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            'Search vehicle name or plate...',
                                        hintStyle: GoogleFonts.roboto(
                                          color: colorScheme.onSurface
                                              .withOpacity(0.5),
                                          fontSize: fsSecondary,
                                          height: 16 / 12,
                                        ),
                                        prefixIcon: Icon(
                                          CupertinoIcons.search,
                                          size: iconSize + 2,
                                          color: colorScheme.onSurface,
                                        ),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: padding,
                                          vertical: padding,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: padding),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final double gap = spacing;
                                      final double cellWidth =
                                          (constraints.maxWidth - gap * 2) / 3;
                                      return Wrap(
                                        spacing: gap,
                                        runSpacing: gap,
                                        children: [
                                          SizedBox(
                                            width: cellWidth,
                                            child: PopupMenuButton<String>(
                                              onSelected: (value) {
                                                if (_vehicleFilter == value) {
                                                  return;
                                                }
                                                setState(
                                                  () => _vehicleFilter = value,
                                                );
                                              },
                                              itemBuilder: (context) => const [
                                                PopupMenuItem(
                                                  value: 'All',
                                                  child: Text('All'),
                                                ),
                                                PopupMenuItem(
                                                  value: 'Enabled',
                                                  child: Text('Enabled'),
                                                ),
                                                PopupMenuItem(
                                                  value: 'Disabled',
                                                  child: Text('Disabled'),
                                                ),
                                              ],
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: padding,
                                                  vertical: spacing,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.surface,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: colorScheme.onSurface
                                                        .withOpacity(0.1),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.tune,
                                                      size: iconSize,
                                                      color: colorScheme.onSurface,
                                                    ),
                                                    SizedBox(width: spacing / 2),
                                                    Text(
                                                      'Filter',
                                                      style: GoogleFonts.roboto(
                                                        fontSize: fsMain - 3,
                                                        height: 20 / 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            colorScheme.onSurface,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: cellWidth,
                                            child: PopupMenuButton<int>(
                                              onSelected: (value) {
                                                if (_vehiclePageSize == value) {
                                                  return;
                                                }
                                                setState(
                                                  () => _vehiclePageSize = value,
                                                );
                                              },
                                              itemBuilder: (context) => const [
                                                PopupMenuItem(
                                                  value: 10,
                                                  child: Text('10'),
                                                ),
                                                PopupMenuItem(
                                                  value: 25,
                                                  child: Text('25'),
                                                ),
                                                PopupMenuItem(
                                                  value: 50,
                                                  child: Text('50'),
                                                ),
                                              ],
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: padding,
                                                  vertical: spacing,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.surface,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: colorScheme.onSurface
                                                        .withOpacity(0.1),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Records',
                                                      style: GoogleFonts.roboto(
                                                        fontSize: fsMain - 3,
                                                        height: 20 / 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            colorScheme.onSurface,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    SizedBox(width: spacing / 2),
                                                    Icon(
                                                      Icons.keyboard_arrow_down,
                                                      size: iconSize,
                                                      color: colorScheme.onSurface,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: cellWidth,
                                            child: InkWell(
                                              onTap: _loadSettings,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              splashColor: Colors.transparent,
                                              highlightColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: padding,
                                                  vertical: spacing,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.surface,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: colorScheme.onSurface
                                                        .withOpacity(0.1),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.refresh,
                                                      size: iconSize,
                                                      color: colorScheme.onSurface,
                                                    ),
                                                    SizedBox(width: spacing / 2),
                                                    Text(
                                                      'Refresh',
                                                      style: GoogleFonts.roboto(
                                                        fontSize: fsMain - 3,
                                                        height: 20 / 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            colorScheme.onSurface,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  SizedBox(height: padding),
                                  Builder(
                                    builder: (context) {
                                      final query = _vehicleSearchController.text
                                          .trim()
                                          .toLowerCase();
                                      var filtered = vehicles.where((v) {
                                        final label =
                                            '${v.name} ${v.plateNumber}'
                                                .toLowerCase();
                                        if (query.isNotEmpty &&
                                            !label.contains(query)) {
                                          return false;
                                        }
                                        final rule =
                                            _basicRuleFor(v.id.toString());
                                        final enabled = (rule?.ignitionEnabled ??
                                                false) ||
                                            (rule?.alarmEnabled ?? false);
                                        if (_vehicleFilter == 'Enabled') {
                                          return enabled;
                                        }
                                        if (_vehicleFilter == 'Disabled') {
                                          return !enabled;
                                        }
                                        return true;
                                      }).toList();

                                      if (filtered.length > _vehiclePageSize) {
                                        filtered =
                                            filtered.take(_vehiclePageSize).toList();
                                      }

                                      if (filtered.isEmpty) {
                                        return Text(
                                          'No vehicles found',
                                          style: GoogleFonts.roboto(
                                            fontSize: fsSecondary,
                                            height: 16 / 12,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface
                                                .withOpacity(0.6),
                                          ),
                                        );
                                      }

                                      return Column(
                                        children: filtered.map((vehicle) {
                                          final rule = _basicRuleFor(
                                            vehicle.id.toString(),
                                          );
                                          final ignitionEnabled =
                                              rule?.ignitionEnabled ?? false;
                                          final alarmEnabled =
                                              rule?.alarmEnabled ?? false;
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(bottom: 12),
                                            child: _vehicleAlertCard(
                                              context,
                                              vehicle: vehicle,
                                              ignitionEnabled: ignitionEnabled,
                                              alarmEnabled: alarmEnabled,
                                              onIgnitionTap: () =>
                                                  _toggleBasicRule(
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
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (_selectedTab.toLowerCase() == 'overspeed') ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(padding),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.onSurface.withOpacity(0.08),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Vehicles',
                                    style: GoogleFonts.roboto(
                                      fontSize: fsSection,
                                      height: 24 / 18,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  SizedBox(height: padding),
                                  Container(
                                    height: padding * 3.5,
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color:
                                            colorScheme.onSurface.withOpacity(0.1),
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _vehicleSearchController,
                                      onChanged: (_) => setState(() {}),
                                      style: GoogleFonts.roboto(
                                        fontSize: fsMain,
                                        height: 20 / 14,
                                        color: colorScheme.onSurface,
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            'Search vehicle name or plate...',
                                        hintStyle: GoogleFonts.roboto(
                                          color: colorScheme.onSurface
                                              .withOpacity(0.5),
                                          fontSize: fsSecondary,
                                          height: 16 / 12,
                                        ),
                                        prefixIcon: Icon(
                                          CupertinoIcons.search,
                                          size: iconSize + 2,
                                          color: colorScheme.onSurface,
                                        ),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: padding,
                                          vertical: padding,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: padding),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final double gap = spacing;
                                      final double cellWidth =
                                          (constraints.maxWidth - gap * 2) / 3;
                                      return Wrap(
                                        spacing: gap,
                                        runSpacing: gap,
                                        children: [
                                          SizedBox(
                                            width: cellWidth,
                                            child: PopupMenuButton<String>(
                                              onSelected: (value) {
                                                if (_vehicleFilter == value) {
                                                  return;
                                                }
                                                setState(
                                                  () => _vehicleFilter = value,
                                                );
                                              },
                                              itemBuilder: (context) => const [
                                                PopupMenuItem(
                                                  value: 'All',
                                                  child: Text('All'),
                                                ),
                                                PopupMenuItem(
                                                  value: 'Enabled',
                                                  child: Text('Enabled'),
                                                ),
                                                PopupMenuItem(
                                                  value: 'Disabled',
                                                  child: Text('Disabled'),
                                                ),
                                              ],
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: padding,
                                                  vertical: spacing,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.surface,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: colorScheme.onSurface
                                                        .withOpacity(0.1),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.tune,
                                                      size: iconSize,
                                                      color: colorScheme.onSurface,
                                                    ),
                                                    SizedBox(width: spacing / 2),
                                                    Text(
                                                      'Filter',
                                                      style: GoogleFonts.roboto(
                                                        fontSize: fsMain - 3,
                                                        height: 20 / 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            colorScheme.onSurface,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: cellWidth,
                                            child: PopupMenuButton<int>(
                                              onSelected: (value) {
                                                if (_vehiclePageSize == value) {
                                                  return;
                                                }
                                                setState(
                                                  () => _vehiclePageSize = value,
                                                );
                                              },
                                              itemBuilder: (context) => const [
                                                PopupMenuItem(
                                                  value: 10,
                                                  child: Text('10'),
                                                ),
                                                PopupMenuItem(
                                                  value: 25,
                                                  child: Text('25'),
                                                ),
                                                PopupMenuItem(
                                                  value: 50,
                                                  child: Text('50'),
                                                ),
                                              ],
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: padding,
                                                  vertical: spacing,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.surface,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: colorScheme.onSurface
                                                        .withOpacity(0.1),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Records',
                                                      style: GoogleFonts.roboto(
                                                        fontSize: fsMain - 3,
                                                        height: 20 / 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            colorScheme.onSurface,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    SizedBox(width: spacing / 2),
                                                    Icon(
                                                      Icons.keyboard_arrow_down,
                                                      size: iconSize,
                                                      color: colorScheme.onSurface,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: cellWidth,
                                            child: InkWell(
                                              onTap: _loadSettings,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              splashColor: Colors.transparent,
                                              highlightColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: padding,
                                                  vertical: spacing,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.surface,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: colorScheme.onSurface
                                                        .withOpacity(0.1),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.refresh,
                                                      size: iconSize,
                                                      color: colorScheme.onSurface,
                                                    ),
                                                    SizedBox(width: spacing / 2),
                                                    Text(
                                                      'Refresh',
                                                      style: GoogleFonts.roboto(
                                                        fontSize: fsMain - 3,
                                                        height: 20 / 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            colorScheme.onSurface,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  SizedBox(height: padding),
                                  Builder(
                                    builder: (context) {
                                      final query = _vehicleSearchController.text
                                          .trim()
                                          .toLowerCase();
                                      var filtered = vehicles.where((v) {
                                        final label =
                                            '${v.name} ${v.plateNumber}'
                                                .toLowerCase();
                                        if (query.isNotEmpty &&
                                            !label.contains(query)) {
                                          return false;
                                        }
                                        final rule =
                                            _overspeedRuleFor(v.id.toString());
                                        final enabled = rule?.enabled ?? false;
                                        if (_vehicleFilter == 'Enabled') {
                                          return enabled;
                                        }
                                        if (_vehicleFilter == 'Disabled') {
                                          return !enabled;
                                        }
                                        return true;
                                      }).toList();

                                      if (filtered.length > _vehiclePageSize) {
                                        filtered =
                                            filtered.take(_vehiclePageSize).toList();
                                      }

                                      if (filtered.isEmpty) {
                                        return Text(
                                          'No vehicles found',
                                          style: GoogleFonts.roboto(
                                            fontSize: fsSecondary,
                                            height: 16 / 12,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface
                                                .withOpacity(0.6),
                                          ),
                                        );
                                      }

                                      return Column(
                                        children: filtered.map((vehicle) {
                                          final rule = _overspeedRuleFor(
                                            vehicle.id.toString(),
                                          );
                                          final speed =
                                              rule?.speedLimitKph;
                                          final controller =
                                              _speedControllerFor(
                                            vehicle.id.toString(),
                                            speed,
                                          );
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(bottom: 12),
                                            child: _vehicleSpeedCard(
                                              context,
                                              vehicle: vehicle,
                                              controller: controller,
                                              onSubmit: (value) {
                                                final parsed =
                                                    int.tryParse(value.trim());
                                                _updateOverspeedRule(
                                                  vehicle: vehicle,
                                                  speedLimit: parsed,
                                                );
                                              },
                                            ),
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (_selectedTab.toLowerCase() == 'geofence') ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(padding),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.onSurface.withOpacity(0.08),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Vehicles',
                                    style: GoogleFonts.roboto(
                                      fontSize: fsSection,
                                      height: 24 / 18,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  SizedBox(height: padding),
                                  Container(
                                    height: padding * 3.5,
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color:
                                            colorScheme.onSurface.withOpacity(0.1),
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _vehicleSearchController,
                                      onChanged: (_) => setState(() {}),
                                      style: GoogleFonts.roboto(
                                        fontSize: fsMain,
                                        height: 20 / 14,
                                        color: colorScheme.onSurface,
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            'Search vehicle name or plate...',
                                        hintStyle: GoogleFonts.roboto(
                                          color: colorScheme.onSurface
                                              .withOpacity(0.5),
                                          fontSize: fsSecondary,
                                          height: 16 / 12,
                                        ),
                                        prefixIcon: Icon(
                                          CupertinoIcons.search,
                                          size: iconSize + 2,
                                          color: colorScheme.onSurface,
                                        ),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: padding,
                                          vertical: padding,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: padding),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final double gap = spacing;
                                      final double cellWidth =
                                          (constraints.maxWidth - gap * 2) / 3;
                                      return Wrap(
                                        spacing: gap,
                                        runSpacing: gap,
                                        children: [
                                          SizedBox(
                                            width: cellWidth,
                                            child: PopupMenuButton<String>(
                                              onSelected: (value) {
                                                if (_vehicleFilter == value) {
                                                  return;
                                                }
                                                setState(
                                                  () => _vehicleFilter = value,
                                                );
                                              },
                                              itemBuilder: (context) => const [
                                                PopupMenuItem(
                                                  value: 'All',
                                                  child: Text('All'),
                                                ),
                                                PopupMenuItem(
                                                  value: 'Enabled',
                                                  child: Text('Enabled'),
                                                ),
                                                PopupMenuItem(
                                                  value: 'Disabled',
                                                  child: Text('Disabled'),
                                                ),
                                              ],
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: padding,
                                                  vertical: spacing,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.surface,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: colorScheme.onSurface
                                                        .withOpacity(0.1),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.tune,
                                                      size: iconSize,
                                                      color: colorScheme.onSurface,
                                                    ),
                                                    SizedBox(width: spacing / 2),
                                                    Text(
                                                      'Filter',
                                                      style: GoogleFonts.roboto(
                                                        fontSize: fsMain - 3,
                                                        height: 20 / 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            colorScheme.onSurface,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: cellWidth,
                                            child: PopupMenuButton<int>(
                                              onSelected: (value) {
                                                if (_vehiclePageSize == value) {
                                                  return;
                                                }
                                                setState(
                                                  () => _vehiclePageSize = value,
                                                );
                                              },
                                              itemBuilder: (context) => const [
                                                PopupMenuItem(
                                                  value: 10,
                                                  child: Text('10'),
                                                ),
                                                PopupMenuItem(
                                                  value: 25,
                                                  child: Text('25'),
                                                ),
                                                PopupMenuItem(
                                                  value: 50,
                                                  child: Text('50'),
                                                ),
                                              ],
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: padding,
                                                  vertical: spacing,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.surface,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: colorScheme.onSurface
                                                        .withOpacity(0.1),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Records',
                                                      style: GoogleFonts.roboto(
                                                        fontSize: fsMain - 3,
                                                        height: 20 / 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            colorScheme.onSurface,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    SizedBox(width: spacing / 2),
                                                    Icon(
                                                      Icons.keyboard_arrow_down,
                                                      size: iconSize,
                                                      color: colorScheme.onSurface,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: cellWidth,
                                            child: InkWell(
                                              onTap: _loadSettings,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              splashColor: Colors.transparent,
                                              highlightColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: padding,
                                                  vertical: spacing,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.surface,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: colorScheme.onSurface
                                                        .withOpacity(0.1),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.refresh,
                                                      size: iconSize,
                                                      color: colorScheme.onSurface,
                                                    ),
                                                    SizedBox(width: spacing / 2),
                                                    Text(
                                                      'Refresh',
                                                      style: GoogleFonts.roboto(
                                                        fontSize: fsMain - 3,
                                                        height: 20 / 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            colorScheme.onSurface,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  SizedBox(height: padding),
                                  Builder(
                                    builder: (context) {
                                      final query = _vehicleSearchController.text
                                          .trim()
                                          .toLowerCase();
                                      var filtered = vehicles.where((v) {
                                        final label =
                                            '${v.name} ${v.plateNumber}'
                                                .toLowerCase();
                                        if (query.isNotEmpty &&
                                            !label.contains(query)) {
                                          return false;
                                        }
                                        final enabled =
                                            _geofenceEnabledFor(v.id.toString());
                                        if (_vehicleFilter == 'Enabled') {
                                          return enabled;
                                        }
                                        if (_vehicleFilter == 'Disabled') {
                                          return !enabled;
                                        }
                                        return true;
                                      }).toList();

                                      if (filtered.length > _vehiclePageSize) {
                                        filtered =
                                            filtered.take(_vehiclePageSize).toList();
                                      }

                                      if (filtered.isEmpty) {
                                        return Text(
                                          'No vehicles found',
                                          style: GoogleFonts.roboto(
                                            fontSize: fsSecondary,
                                            height: 16 / 12,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface
                                                .withOpacity(0.6),
                                          ),
                                        );
                                      }

                                      return Column(
                                        children: filtered.map((vehicle) {
                                          final enabled = _geofenceEnabledFor(
                                            vehicle.id.toString(),
                                          );
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(bottom: 12),
                                            child: _vehicleGeofenceCard(
                                              context,
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
                                    },
                                  ),
                                ],
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
                  ? const Color(0xFF0A0A0A)
                  : const Color(0xFFF5F5F7),
              child: UserHomeAppBar(
                title: 'Notifications',
                leadingIcon: Icons.notifications_outlined,
                onClose: () => context.go('/user/home'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _channelRow(
  BuildContext context, {
  required String label,
  required IconData icon,
  required bool enabled,
  required VoidCallback onTap,
}) {
  final cs = Theme.of(context).colorScheme;
  final width = MediaQuery.of(context).size.width;
  final fs = AdaptiveUtils.getTitleFontSize(width);
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: cs.onSurface.withOpacity(0.08)),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? cs.surfaceVariant
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: cs.onSurface),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: fs,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: enabled ? cs.primary.withOpacity(0.12) : cs.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: enabled ? cs.primary : cs.onSurface.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  enabled ? Icons.check_circle : Icons.circle_outlined,
                  size: 16,
                  color: enabled ? cs.primary : cs.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  enabled ? 'Enabled' : 'Enable',
                  style: GoogleFonts.roboto(
                    fontSize: fs - 2,
                    height: 16 / 12,
                    fontWeight: FontWeight.w600,
                    color: enabled ? cs.primary : cs.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _vehicleAlertCard(
  BuildContext context, {
  required UserNotificationVehicle vehicle,
  required bool ignitionEnabled,
  required bool alarmEnabled,
  required VoidCallback onIgnitionTap,
  required VoidCallback onAlarmTap,
}) {
  final cs = Theme.of(context).colorScheme;
  final width = MediaQuery.of(context).size.width;
  final fs = AdaptiveUtils.getTitleFontSize(width);
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: cs.onSurface.withOpacity(0.08)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? cs.surfaceVariant
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                vehicle.name.isNotEmpty
                    ? vehicle.name.trim()[0].toUpperCase()
                    : 'V',
                style: GoogleFonts.roboto(
                  fontSize: fs,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.name.isEmpty ? 'Vehicle' : vehicle.name,
                    style: GoogleFonts.roboto(
                      fontSize: fs,
                      height: 20 / 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vehicle.plateNumber.isEmpty
                        ? '—'
                        : vehicle.plateNumber,
                    style: GoogleFonts.roboto(
                      fontSize: fs - 2,
                      height: 16 / 12,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.onSurface.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onIgnitionTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: ignitionEnabled ? cs.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.power_settings_new_outlined,
                          size: 16,
                          color: ignitionEnabled
                              ? cs.onPrimary
                              : cs.onSurface,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Ignition',
                          style: GoogleFonts.roboto(
                            fontSize: fs - 1,
                            height: 18 / 13,
                            fontWeight: FontWeight.w600,
                            color: ignitionEnabled
                                ? cs.onPrimary
                                : cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: onAlarmTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: alarmEnabled ? cs.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          size: 16,
                          color:
                              alarmEnabled ? cs.onPrimary : cs.onSurface,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Alarm',
                          style: GoogleFonts.roboto(
                            fontSize: fs - 1,
                            height: 18 / 13,
                            fontWeight: FontWeight.w600,
                            color:
                                alarmEnabled ? cs.onPrimary : cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _vehicleSpeedCard(
  BuildContext context, {
  required UserNotificationVehicle vehicle,
  required TextEditingController controller,
  required ValueChanged<String> onSubmit,
}) {
  final cs = Theme.of(context).colorScheme;
  final width = MediaQuery.of(context).size.width;
  final fs = AdaptiveUtils.getTitleFontSize(width);
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: cs.onSurface.withOpacity(0.08)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? cs.surfaceVariant
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                vehicle.name.isNotEmpty
                    ? vehicle.name.trim()[0].toUpperCase()
                    : 'V',
                style: GoogleFonts.roboto(
                  fontSize: fs,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.name.isEmpty ? 'Vehicle' : vehicle.name,
                    style: GoogleFonts.roboto(
                      fontSize: fs,
                      height: 20 / 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vehicle.plateNumber.isEmpty ? '—' : vehicle.plateNumber,
                    style: GoogleFonts.roboto(
                      fontSize: fs - 2,
                      height: 16 / 12,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Speed Limit (kph)',
          style: GoogleFonts.roboto(
            fontSize: fs - 2,
            height: 16 / 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onSubmitted: onSubmit,
          style: GoogleFonts.roboto(
            fontSize: fs,
            height: 20 / 14,
            color: cs.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Enter speed limit',
            hintStyle: GoogleFonts.roboto(
              fontSize: fs - 1,
              height: 20 / 14,
              color: cs.onSurface.withOpacity(0.5),
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.check_circle, color: cs.primary),
              onPressed: () => onSubmit(controller.text),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: cs.onSurface.withOpacity(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: cs.onSurface.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: cs.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _vehicleGeofenceCard(
  BuildContext context, {
  required UserNotificationVehicle vehicle,
  required bool enabled,
  required VoidCallback onToggle,
}) {
  final cs = Theme.of(context).colorScheme;
  final width = MediaQuery.of(context).size.width;
  final fs = AdaptiveUtils.getTitleFontSize(width);
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: cs.onSurface.withOpacity(0.08)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? cs.surfaceVariant
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                vehicle.name.isNotEmpty
                    ? vehicle.name.trim()[0].toUpperCase()
                    : 'V',
                style: GoogleFonts.roboto(
                  fontSize: fs,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.name.isEmpty ? 'Vehicle' : vehicle.name,
                    style: GoogleFonts.roboto(
                      fontSize: fs,
                      height: 20 / 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vehicle.plateNumber.isEmpty ? '—' : vehicle.plateNumber,
                    style: GoogleFonts.roboto(
                      fontSize: fs - 2,
                      height: 16 / 12,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? cs.surfaceVariant
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.location_on_outlined,
                size: 16,
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Test Zone',
                style: GoogleFonts.roboto(
                  fontSize: fs,
                  height: 20 / 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: enabled ? cs.primary.withOpacity(0.12) : cs.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: enabled ? cs.primary : cs.onSurface.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      enabled ? Icons.check_circle : Icons.circle_outlined,
                      size: 16,
                      color: enabled ? cs.primary : cs.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      enabled ? 'Enabled' : 'Enable',
                      style: GoogleFonts.roboto(
                        fontSize: fs - 2,
                        height: 16 / 12,
                        fontWeight: FontWeight.w600,
                        color: enabled
                            ? cs.primary
                            : cs.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _NavigateBox extends StatelessWidget {
  final String selectedTab;
  final List<String> tabs;
  final ValueChanged<String> onTabSelected;

  const _NavigateBox({
    required this.selectedTab,
    required this.tabs,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double scale = (screenWidth / 420).clamp(0.9, 1.0);
    final double fsSection = 18 * scale;
    final double fsSubtitle = 12 * scale;
    final double fsTab = 13 * scale;
    final double fsTabIcon = 14 * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
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
            'Push Notifications',
            style: GoogleFonts.roboto(
              fontSize: fsSection,
              height: 24 / 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage alert channels for each category',
            style: GoogleFonts.roboto(
              fontSize: fsSubtitle,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: tabs.map((tab) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _SettingsTab(
                      label: tab,
                      selected: selectedTab == tab,
                      icon: _iconFor(tab),
                      fontSize: fsTab,
                      iconSize: fsTabIcon,
                      onTap: () => onTabSelected(tab),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData? _iconFor(String tab) {
    final t = tab.toLowerCase();
    if (t == 'basic') return Icons.notifications_active_outlined;
    if (t == 'overspeed') return Icons.speed_outlined;
    if (t == 'geofence') return Icons.location_on_outlined;
    return null;
  }
}

class _SettingsTab extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final double fontSize;
  final double iconSize;
  final VoidCallback onTap;

  const _SettingsTab({
    required this.label,
    required this.selected,
    required this.icon,
    required this.fontSize,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? cs.primary : cs.onSurface.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: iconSize,
                  color: selected ? cs.onPrimary : cs.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: fontSize,
                  height: 18 / 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? cs.onPrimary : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreMenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final double width;
  final double hp;
  final bool isListMode;

  const _MoreMenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.width,
    required this.hp,
    this.isListMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final double iconContainerSize = isListMode
        ? AdaptiveUtils.getAvatarSize(width) * 1.1
        : AdaptiveUtils.getAvatarSize(width) * 1.3;

    final double innerIconSize = AdaptiveUtils.getIconSize(width);

    final EdgeInsets cardPadding = isListMode
        ? EdgeInsets.symmetric(horizontal: hp * 1.2, vertical: hp * 0.7)
        : EdgeInsets.all(hp * 0.8);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.onSurface.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push(route),
        child: Padding(
          padding: cardPadding,
          child: Row(
            children: [
              Container(
                height: iconContainerSize,
                width: iconContainerSize,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: innerIconSize,
                  color: colorScheme.primary,
                ),
              ),
              SizedBox(width: hp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.roboto(
                        fontSize: AdaptiveUtils.getSubtitleFontSize(width),
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.roboto(
                        fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: isListMode ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final double width;
  final double hp;
  final bool isListMode;

  const _LoadingCard({
    required this.width,
    required this.hp,
    this.isListMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final double iconContainerSize = isListMode
        ? AdaptiveUtils.getAvatarSize(width) * 1.1
        : AdaptiveUtils.getAvatarSize(width) * 1.3;

    final EdgeInsets cardPadding = isListMode
        ? EdgeInsets.symmetric(horizontal: hp * 1.2, vertical: hp * 0.7)
        : EdgeInsets.all(hp * 0.8);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: cardPadding,
        child: Row(
          children: [
            AppShimmer(
              width: iconContainerSize,
              height: iconContainerSize,
              radius: 14,
            ),
            SizedBox(width: hp),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AppShimmer(width: 140, height: 14, radius: 7),
                  SizedBox(height: 6),
                  AppShimmer(width: 200, height: 12, radius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
