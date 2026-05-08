import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_vts/core/models/user_notification_preferences.dart';
import 'package:open_vts/core/network/api_exception.dart';
import 'package:open_vts/modules/user/screens/notification/push_notification/config.dart';
import 'package:open_vts/modules/user/screens/notification/push_notification/models.dart';
import 'package:open_vts/modules/user/screens/notification/push_notification/repository.dart';

class PushNotificationController extends ChangeNotifier {
  PushNotificationController({required PushNotificationRepository repository})
    : _repository = repository;

  final PushNotificationRepository _repository;

  final List<UserNotificationPreferenceItem> _items =
      <UserNotificationPreferenceItem>[];
  UserNotificationPreferences? _prefs;

  final TextEditingController vehicleSearchController =
      TextEditingController();
  String _vehicleFilter = PushNotificationConfig.vehicleFilters.first;
  int _vehiclePageSize = PushNotificationConfig.vehiclePageSizes.first;

  final Map<String, TextEditingController> _speedControllers =
      <String, TextEditingController>{};
  final Map<String, bool> _geofenceOverrides = <String, bool>{};

  bool _loading = false;
  bool _errorShown = false;
  bool _overspeedDirty = false;
  bool _savingOverspeed = false;
  final Set<String> _updating = <String>{};

  CancelToken? _token;
  PushNotificationTab _selectedTab = PushNotificationTab.basic;

  bool get loading => _loading;
  bool get overspeedDirty => _overspeedDirty;
  bool get savingOverspeed => _savingOverspeed;
  bool get hasSettings => _items.isNotEmpty;

  String get selectedTabLabel => _selectedTab.label;
  String get tabTitle => _selectedTab.title;

  String get vehicleFilter => _vehicleFilter;
  int get vehiclePageSize => _vehiclePageSize;

  List<String> get tabs => PushNotificationConfig.tabs;

  UserNotificationPreferenceItem? preferenceForSelectedTab() {
    final wanted = _selectedTab.eventType;
    for (final item in _items) {
      if (item.eventType == wanted) {
        return item;
      }
    }
    return null;
  }

  void setSelectedTab(String label) {
    final next = PushNotificationTabX.fromLabel(label);
    if (_selectedTab == next) return;
    _selectedTab = next;
    notifyListeners();
  }

  void setVehicleFilter(String filter) {
    if (_vehicleFilter == filter) return;
    _vehicleFilter = filter;
    notifyListeners();
  }

  void setVehiclePageSize(int pageSize) {
    if (_vehiclePageSize == pageSize) return;
    _vehiclePageSize = pageSize;
    notifyListeners();
  }

  void onVehicleQueryChanged() {
    notifyListeners();
  }

  List<UserNotificationVehicle> filteredVehiclesForSelectedTab() {
    final query = vehicleSearchController.text.trim().toLowerCase();
    var filtered = _vehicles().where((vehicle) {
      final label = '${vehicle.name} ${vehicle.plateNumber}'.toLowerCase();
      if (query.isNotEmpty && !label.contains(query)) {
        return false;
      }

      final isEnabled = _vehicleEnabledForSelectedTab(vehicle.id.toString());
      if (_vehicleFilter == 'Enabled') {
        return isEnabled;
      }
      if (_vehicleFilter == 'Disabled') {
        return !isEnabled;
      }
      return true;
    }).toList();

    if (filtered.length > _vehiclePageSize) {
      filtered = filtered.take(_vehiclePageSize).toList();
    }

    return filtered;
  }

  UserBasicAlertRule? basicRuleFor(String vehicleId) {
    return _prefs?.basicRuleFor(vehicleId);
  }

  UserOverspeedRule? overspeedRuleFor(String vehicleId) {
    return _prefs?.overspeedRuleFor(vehicleId);
  }

  bool geofenceEnabledFor(String vehicleId) {
    final override = _geofenceOverrides[vehicleId];
    if (override != null) return override;

    final data = _prefs?.data ?? const <String, dynamic>{};
    final list = (data['geofenceMatrix'] is List)
        ? data['geofenceMatrix'] as List
        : (data['geofences'] is List ? data['geofences'] as List : const []);

    for (final item in list) {
      if (item is! Map) continue;
      final vehicle = item['vehicleId']?.toString() ?? item['id']?.toString();
      if (vehicle != vehicleId) continue;

      final enabled = item['enabled'] ?? item['isEnabled'] ?? item['active'];
      return _asBool(enabled);
    }

    return false;
  }

  TextEditingController speedControllerFor(String vehicleId, int? speed) {
    final existing = _speedControllers[vehicleId];
    if (existing != null) return existing;

    final controller = TextEditingController(
      text: speed == null ? '' : speed.toString(),
    );
    _speedControllers[vehicleId] = controller;
    return controller;
  }

  Future<PushNotificationActionResult?> loadSettings() async {
    _token?.cancel('Reload push notification settings');
    final token = CancelToken();
    _token = token;

    _loading = true;
    notifyListeners();

    try {
      final res = await _repository.getPreferences(cancelToken: token);
      if (token.isCancelled) return null;

      PushNotificationActionResult? result;
      res.when(
        success: (prefs) {
          _prefs = prefs;
          _items
            ..clear()
            ..addAll(prefs.items);
          _loading = false;
          _errorShown = false;
        },
        failure: (error) {
          _items.clear();
          _loading = false;
          result = _errorResult(
            error,
            fallback: "Couldn't load notification settings.",
          );
        },
      );

      notifyListeners();
      return result;
    } catch (_) {
      _items.clear();
      _loading = false;
      notifyListeners();
      return _errorResult(null, fallback: "Couldn't load notification settings.");
    }
  }

  Future<PushNotificationActionResult?> toggleChannel({
    required UserNotificationPreferenceItem item,
    required String key,
    required String label,
    bool? mobile,
    bool? whatsapp,
    bool? email,
  }) async {
    if (_updating.contains(key)) return null;
    _updating.add(key);
    notifyListeners();

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

    final previousIndex = _items.indexWhere((e) => e.eventType == item.eventType);
    if (previousIndex != -1) {
      _items[previousIndex] = updated;
      notifyListeners();
    }

    PushNotificationActionResult? result;
    final res = await _repository.updatePreference(updated);
    res.when(
      success: (_) {
        result = PushNotificationActionResult.success(
          '${item.eventType} • $label ${enabledNow ? 'enabled' : 'disabled'}',
        );
      },
      failure: (error) {
        if (previousIndex != -1) {
          _items[previousIndex] = item;
        }
        result = _errorResult(error, fallback: "Couldn't update $label.");
      },
    );

    _updating.remove(key);
    notifyListeners();
    return result;
  }

  Future<PushNotificationActionResult?> toggleBasicRule({
    required UserNotificationVehicle vehicle,
    bool? ignition,
    bool? alarm,
  }) async {
    final key = 'basic:${vehicle.id}';
    if (_updating.contains(key)) return null;
    _updating.add(key);
    notifyListeners();

    final prefs = _prefs;
    if (prefs == null) {
      _updating.remove(key);
      notifyListeners();
      return null;
    }

    final current = prefs.basicRuleFor(vehicle.id.toString());
    final baseRule =
        current ??
        UserBasicAlertRule(<String, dynamic>{
          'vehicleId': vehicle.id,
          'ignitionEnabled': false,
          'alarmEnabled': false,
        });

    final nextRule = baseRule.copyWith(
      ignitionEnabled: ignition ?? current?.ignitionEnabled ?? false,
      alarmEnabled: alarm ?? current?.alarmEnabled ?? false,
    );

    final updatedRules = <UserBasicAlertRule>[
      ...prefs.basicRules.where((rule) => rule.vehicleId != vehicle.id.toString()),
      nextRule,
    ];

    final nextPrefs = prefs.copyWith(basicRules: updatedRules);
    _prefs = nextPrefs;
    notifyListeners();

    final payload = nextPrefs.toUpdatePayload();
    _copyGeofencePayload(from: prefs, into: payload);

    PushNotificationActionResult? result;
    final res = await _repository.updatePreferencesPayload(payload);
    res.when(
      success: (_) {
        result = PushNotificationActionResult.success(
          '${vehicle.name} • Basic alerts updated',
        );
      },
      failure: (error) {
        _prefs = prefs;
        result = _errorResult(error, fallback: "Couldn't update basic alerts.");
      },
    );

    _updating.remove(key);
    notifyListeners();
    return result;
  }

  void updateOverspeedRule({
    required UserNotificationVehicle vehicle,
    int? speedLimit,
    bool? enabled,
  }) {
    final prefs = _prefs;
    if (prefs == null) return;

    final current = prefs.overspeedRuleFor(vehicle.id.toString());
    final nextEnabled = enabled ?? current?.enabled ?? false;
    final nextSpeedLimit = speedLimit ?? current?.speedLimitKph;

    final nextRule =
        (current ??
                UserOverspeedRule(<String, dynamic>{
                  'vehicleId': vehicle.id,
                  'enabled': nextEnabled,
                  'speedLimitKph': nextSpeedLimit,
                }))
            .copyWith(enabled: nextEnabled, speedLimitKph: nextSpeedLimit);

    final updatedRules = <UserOverspeedRule>[
      ...prefs.overspeedRules.where((rule) => rule.vehicleId != vehicle.id.toString()),
      nextRule,
    ];

    _prefs = prefs.copyWith(overspeedRules: updatedRules);
    _overspeedDirty = true;
    notifyListeners();
  }

  Future<PushNotificationActionResult?> saveOverspeedChanges() async {
    if (_savingOverspeed || !_overspeedDirty) return null;
    final prefs = _prefs;
    if (prefs == null) return null;

    for (final rule in prefs.overspeedRules) {
      if (rule.enabled) {
        final speed = rule.speedLimitKph;
        if (speed == null || speed <= 0) {
          return PushNotificationActionResult.error(
            'Set a valid speed limit for all enabled overspeed vehicles.',
          );
        }
      }
    }

    _savingOverspeed = true;
    notifyListeners();

    final payload = prefs.toUpdatePayload();
    payload['overspeed'] = prefs.overspeedRules
        .map(
          (rule) => <String, dynamic>{
            'vehicleId': int.tryParse(rule.vehicleId) ?? rule.vehicleId,
            'enabled': rule.enabled,
            'speedLimitKph': rule.enabled ? rule.speedLimitKph : null,
          },
        )
        .toList();

    final geofenceMatrix = prefs.data['geofenceMatrix'];
    if (geofenceMatrix is List) {
      payload['geofenceMatrix'] = geofenceMatrix;
    }

    PushNotificationActionResult? result;
    final res = await _repository.updatePreferencesPayload(payload);
    res.when(
      success: (_) {
        _overspeedDirty = false;
        result = PushNotificationActionResult.success('Overspeed preferences saved');
      },
      failure: (error) {
        final message =
            error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't save overspeed preferences.";
        result = PushNotificationActionResult.error(message);
      },
    );

    _savingOverspeed = false;
    notifyListeners();
    return result;
  }

  Future<PushNotificationActionResult?> toggleGeofenceRule({
    required UserNotificationVehicle vehicle,
    required bool enabled,
  }) async {
    final key = 'geofence:${vehicle.id}';
    if (_updating.contains(key)) return null;

    _updating.add(key);
    _geofenceOverrides[vehicle.id.toString()] = enabled;
    notifyListeners();

    final prefs = _prefs;
    if (prefs == null) {
      _updating.remove(key);
      notifyListeners();
      return null;
    }

    final matrix = <Map<String, dynamic>>[];
    final existing = prefs.data['geofenceMatrix'];
    if (existing is List) {
      for (final item in existing) {
        if (item is Map) {
          matrix.add(Map<String, dynamic>.from(item));
        }
      }
    }

    final vehicleId = vehicle.id.toString();
    final index = matrix.indexWhere(
      (entry) =>
          entry['vehicleId']?.toString() == vehicleId ||
          entry['id']?.toString() == vehicleId,
    );

    final nextItem = <String, dynamic>{
      'vehicleId': int.tryParse(vehicleId) ?? vehicleId,
      'enabled': enabled,
      'zone': PushNotificationConfig.geofenceZoneName,
    };

    if (index >= 0) {
      matrix[index] = nextItem;
    } else {
      matrix.add(nextItem);
    }

    final payload = prefs.toUpdatePayload();
    payload['geofenceMatrix'] = matrix;

    PushNotificationActionResult? result;
    final res = await _repository.updatePreferencesPayload(payload);
    res.when(
      success: (_) {
        result = PushNotificationActionResult.success(
          '${vehicle.name} • ${PushNotificationConfig.geofenceZoneName} ${enabled ? 'enabled' : 'disabled'}',
        );
      },
      failure: (error) {
        result = _errorResult(error, fallback: "Couldn't update geofence.");
      },
    );

    _updating.remove(key);
    notifyListeners();
    return result;
  }

  bool _vehicleEnabledForSelectedTab(String vehicleId) {
    switch (_selectedTab) {
      case PushNotificationTab.basic:
        final rule = basicRuleFor(vehicleId);
        return (rule?.ignitionEnabled ?? false) || (rule?.alarmEnabled ?? false);
      case PushNotificationTab.overspeed:
        return overspeedRuleFor(vehicleId)?.enabled ?? false;
      case PushNotificationTab.geofence:
        return geofenceEnabledFor(vehicleId);
    }
  }

  List<UserNotificationVehicle> _vehicles() {
    return _prefs?.vehicles ?? const <UserNotificationVehicle>[];
  }

  void _copyGeofencePayload({
    required UserNotificationPreferences from,
    required Map<String, dynamic> into,
  }) {
    final geofenceMatrix = from.data['geofenceMatrix'];
    if (geofenceMatrix is List) {
      into['geofenceMatrix'] = geofenceMatrix;
    }

    final geofences = from.data['geofences'];
    if (geofences is List) {
      into['geofences'] = geofences;
    }
  }

  PushNotificationActionResult? _errorResult(
    Object? error, {
    required String fallback,
  }) {
    if (_errorShown) return null;

    _errorShown = true;
    final message =
        error is ApiException && error.message.trim().isNotEmpty
        ? error.message
        : fallback;
    return PushNotificationActionResult.error(message);
  }

  bool _asBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' ||
          normalized == '1' ||
          normalized == 'yes' ||
          normalized == 'on';
    }
    return false;
  }

  @override
  void dispose() {
    _token?.cancel('Push notifications disposed');
    vehicleSearchController.dispose();
    for (final controller in _speedControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
