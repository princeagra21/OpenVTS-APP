import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/user_notification_preferences.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_notification_preferences_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/user/layout/app_layout.dart';
import 'package:fleet_stack/modules/user/screens/notification/notification_toggle_tile.dart';
import 'package:flutter/material.dart';

class VehicleToggleScreen extends StatefulWidget {
  final String eventType;

  const VehicleToggleScreen({super.key, required this.eventType});

  @override
  State<VehicleToggleScreen> createState() => _VehicleToggleScreenState();
}

class _VehicleToggleScreenState extends State<VehicleToggleScreen> {
  // FleetStack-API-Reference.md confirmed endpoints:
  // - GET /user/notifications/preferences
  // - PUT /user/notifications/preferences
  // Live curl verification also confirmed the same PUT persists:
  // - basic[] per-vehicle toggles
  // - overspeed[] per-vehicle toggles + speedLimitKph

  UserNotificationPreferences? _prefs;
  UserNotificationPreferenceItem? _item;
  String? _selectedVehicleId;
  bool _loading = false;
  bool _saving = false;
  bool _loadErrorShown = false;

  ApiClient? _api;
  UserNotificationPreferencesRepository? _repo;
  CancelToken? _loadToken;
  CancelToken? _saveToken;

  String get _eventType =>
      Uri.decodeComponent(widget.eventType).trim().toUpperCase();

  bool get _hasVehicleRules =>
      _eventType == 'BASIC' || _eventType == 'OVERSPEED';

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  @override
  void dispose() {
    _loadToken?.cancel('Notification toggle disposed');
    _saveToken?.cancel('Notification toggle disposed');
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

  Future<void> _loadPreference() async {
    _loadToken?.cancel('Reload notification preference');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final res = await _repoOrCreate().getPreferences(cancelToken: token);
      if (!mounted || token.isCancelled) return;

      res.when(
        success: (prefs) {
          final selectedItem =
              prefs.itemFor(_eventType) ??
              UserNotificationPreferenceItem(
                eventType: _eventType,
                notifyEmail: false,
                notifyWhatsapp: false,
                notifyWebPush: false,
                notifyMobilePush: false,
                notifyTelegram: false,
                notifySms: false,
              );
          setState(() {
            _prefs = prefs;
            _item = selectedItem;
            _selectedVehicleId = _pickInitialVehicleId(prefs);
            _loading = false;
            _loadErrorShown = false;
          });
        },
        failure: (error) {
          setState(() => _loading = false);
          if (_loadErrorShown) return;
          _loadErrorShown = true;
          var msg = "Couldn't load notification preference.";
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
      setState(() => _loading = false);
      if (_loadErrorShown) return;
      _loadErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load notification preference.")),
      );
    }
  }

  String? _pickInitialVehicleId(UserNotificationPreferences prefs) {
    if (_eventType == 'BASIC') {
      for (final rule in prefs.basicRules) {
        if (rule.vehicleId.isNotEmpty) return rule.vehicleId;
      }
    }
    if (_eventType == 'OVERSPEED') {
      for (final rule in prefs.overspeedRules) {
        if (rule.vehicleId.isNotEmpty) return rule.vehicleId;
      }
    }
    for (final vehicle in prefs.vehicles) {
      if (vehicle.id.isNotEmpty) return vehicle.id;
    }
    return null;
  }

  Future<void> _persistPrefs(
    UserNotificationPreferences nextPrefs, {
    UserNotificationPreferenceItem? nextItem,
  }) async {
    if (_saving) return;
    final previousPrefs = _prefs;
    final previousItem = _item;
    if (previousPrefs == null) return;

    if (!mounted) return;
    setState(() {
      _prefs = nextPrefs;
      if (nextItem != null) _item = nextItem;
      _saving = true;
    });

    _saveToken?.cancel('Restart notification preference save');
    final token = CancelToken();
    _saveToken = token;

    try {
      final res = await _repoOrCreate().updatePreferencesPayload(
        nextPrefs.toUpdatePayload(),
        cancelToken: token,
      );
      if (!mounted || token.isCancelled) return;
      res.when(
        success: (_) {
          if (!mounted) return;
          setState(() => _saving = false);
        },
        failure: (error) {
          if (!mounted) return;
          setState(() {
            _prefs = previousPrefs;
            _item = previousItem;
            _saving = false;
          });
          var msg = "Couldn't save notification preference.";
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
        _prefs = previousPrefs;
        _item = previousItem;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save notification preference.")),
      );
    }
  }

  Future<void> _updateChannels(UserNotificationPreferenceItem next) async {
    final prefs = _prefs;
    if (prefs == null) return;

    final settings = List<UserNotificationPreferenceItem>.from(prefs.items);
    var replaced = false;
    for (var i = 0; i < settings.length; i++) {
      if (settings[i].eventType == next.eventType) {
        settings[i] = next;
        replaced = true;
        break;
      }
    }
    if (!replaced) settings.add(next);

    await _persistPrefs(prefs.copyWith(settings: settings), nextItem: next);
  }

  UserBasicAlertRule _basicRuleForSelectedVehicle() {
    final vehicleId = (_selectedVehicleId ?? '').trim();
    if (vehicleId.isEmpty) {
      return const UserBasicAlertRule(<String, dynamic>{
        'vehicleId': '',
        'ignitionEnabled': false,
        'alarmEnabled': false,
      });
    }
    return _prefs?.basicRuleFor(vehicleId) ??
        UserBasicAlertRule(<String, dynamic>{
          'vehicleId': int.tryParse(vehicleId) ?? vehicleId,
          'ignitionEnabled': false,
          'alarmEnabled': false,
        });
  }

  UserOverspeedRule _overspeedRuleForSelectedVehicle() {
    final vehicleId = (_selectedVehicleId ?? '').trim();
    if (vehicleId.isEmpty) {
      return const UserOverspeedRule(<String, dynamic>{
        'vehicleId': '',
        'enabled': false,
        'speedLimitKph': null,
      });
    }
    return _prefs?.overspeedRuleFor(vehicleId) ??
        UserOverspeedRule(<String, dynamic>{
          'vehicleId': int.tryParse(vehicleId) ?? vehicleId,
          'enabled': false,
          'speedLimitKph': null,
        });
  }

  Future<void> _updateBasicRule(UserBasicAlertRule next) async {
    final prefs = _prefs;
    if (prefs == null) return;

    final rules = List<UserBasicAlertRule>.from(prefs.basicRules);
    var replaced = false;
    for (var i = 0; i < rules.length; i++) {
      if (rules[i].vehicleId == next.vehicleId) {
        rules[i] = next;
        replaced = true;
        break;
      }
    }
    if (!replaced) rules.add(next);

    await _persistPrefs(prefs.copyWith(basicRules: rules));
  }

  Future<void> _updateOverspeedRule(UserOverspeedRule next) async {
    final prefs = _prefs;
    if (prefs == null) return;

    final rules = List<UserOverspeedRule>.from(prefs.overspeedRules);
    var replaced = false;
    for (var i = 0; i < rules.length; i++) {
      if (rules[i].vehicleId == next.vehicleId) {
        rules[i] = next;
        replaced = true;
        break;
      }
    }
    if (!replaced) rules.add(next);

    await _persistPrefs(prefs.copyWith(overspeedRules: rules));
  }

  String _screenLabel(String eventType) {
    switch (eventType) {
      case 'BASIC':
        return 'Basic Alerts';
      case 'OVERSPEED':
        return 'Overspeed Alerts';
      case 'GEOFENCE':
        return 'Geofence Alerts';
      default:
        return eventType;
    }
  }

  InputDecoration _dropdownDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: 'Vehicle',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;
    final double titleFont = AdaptiveUtils.getSubtitleFontSize(width);
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final item = _item;
    final prefs = _prefs;
    final label = _screenLabel(_eventType);
    final vehicles = prefs?.vehicles ?? const <UserNotificationVehicle>[];
    final basicRule = _basicRuleForSelectedVehicle();
    final overspeedRule = _overspeedRuleForSelectedVehicle();

    return AppLayout(
      title: 'FLEET STACK',
      subtitle: 'Notifications for $label',
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 8,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alerts',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: titleFont,
              ),
            ),
            SizedBox(height: spacing),
            if (_loading) ...[
              for (int i = 0; i < 6; i++) ...[
                const AppShimmer(
                  width: double.infinity,
                  height: 52,
                  radius: 12,
                ),
                SizedBox(height: spacing),
              ],
            ] else ...[
              NotificationToggleTile(
                icon: Icons.email_outlined,
                title: 'Email',
                subtitle: 'Receive $label via email',
                value: item?.notifyEmail ?? false,
                onChanged: (v) {
                  if (_saving || item == null) return;
                  _updateChannels(item.copyWith(notifyEmail: v));
                },
              ),
              SizedBox(height: spacing),
              NotificationToggleTile(
                icon: Icons.phone_android,
                title: 'Mobile Push',
                subtitle: 'Receive $label on mobile push',
                value: item?.notifyMobilePush ?? false,
                onChanged: (v) {
                  if (_saving || item == null) return;
                  _updateChannels(item.copyWith(notifyMobilePush: v));
                },
              ),
              SizedBox(height: spacing),
              NotificationToggleTile(
                icon: Icons.public,
                title: 'Web Push',
                subtitle: 'Receive $label on web push',
                value: item?.notifyWebPush ?? false,
                onChanged: (v) {
                  if (_saving || item == null) return;
                  _updateChannels(item.copyWith(notifyWebPush: v));
                },
              ),
              SizedBox(height: spacing),
              NotificationToggleTile(
                icon: Icons.chat_bubble_outline,
                title: 'WhatsApp',
                subtitle: 'Receive $label on WhatsApp',
                value: item?.notifyWhatsapp ?? false,
                onChanged: (v) {
                  if (_saving || item == null) return;
                  _updateChannels(item.copyWith(notifyWhatsapp: v));
                },
              ),
              SizedBox(height: spacing),
              NotificationToggleTile(
                icon: Icons.send_outlined,
                title: 'Telegram',
                subtitle: 'Receive $label on Telegram',
                value: item?.notifyTelegram ?? false,
                onChanged: (v) {
                  if (_saving || item == null) return;
                  _updateChannels(item.copyWith(notifyTelegram: v));
                },
              ),
              SizedBox(height: spacing),
              NotificationToggleTile(
                icon: Icons.sms_outlined,
                title: 'SMS',
                subtitle: 'Receive $label on SMS',
                value: item?.notifySms ?? false,
                onChanged: (v) {
                  if (_saving || item == null) return;
                  _updateChannels(item.copyWith(notifySms: v));
                },
              ),
              if (_hasVehicleRules) ...[
                SizedBox(height: spacing * 1.5),
                Text(
                  'Vehicle Rules',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: titleFont - 2,
                  ),
                ),
                SizedBox(height: spacing),
                if (vehicles.isEmpty)
                  Text(
                    'No vehicles found for this account.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    initialValue: _selectedVehicleId,
                    decoration: _dropdownDecoration(context),
                    items: vehicles
                        .map(
                          (vehicle) => DropdownMenuItem<String>(
                            value: vehicle.id,
                            child: Text(
                              vehicle.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() => _selectedVehicleId = value);
                          },
                  ),
                  SizedBox(height: spacing),
                  if (_eventType == 'BASIC') ...[
                    NotificationToggleTile(
                      icon: Icons.key_outlined,
                      title: 'Ignition',
                      subtitle:
                          'Enable ignition alerts for the selected vehicle',
                      value: basicRule.ignitionEnabled,
                      onChanged: (v) {
                        if (_saving || _selectedVehicleId == null) return;
                        _updateBasicRule(
                          basicRule.copyWith(ignitionEnabled: v),
                        );
                      },
                    ),
                    SizedBox(height: spacing),
                    NotificationToggleTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Alarm',
                      subtitle: 'Enable alarm alerts for the selected vehicle',
                      value: basicRule.alarmEnabled,
                      onChanged: (v) {
                        if (_saving || _selectedVehicleId == null) return;
                        _updateBasicRule(basicRule.copyWith(alarmEnabled: v));
                      },
                    ),
                  ],
                  if (_eventType == 'OVERSPEED')
                    NotificationToggleTile(
                      icon: Icons.speed_outlined,
                      title: 'Enabled',
                      subtitle: overspeedRule.speedLimitKph == null
                          ? 'Enable overspeed alerts for the selected vehicle'
                          : 'Enable overspeed alerts at ${overspeedRule.speedLimitKph} KPH',
                      value: overspeedRule.enabled,
                      onChanged: (v) {
                        if (_saving || _selectedVehicleId == null) return;
                        _updateOverspeedRule(
                          overspeedRule.copyWith(enabled: v),
                        );
                      },
                    ),
                ],
              ],
            ],
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
