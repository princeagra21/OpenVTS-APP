import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/network/result.dart';
import 'package:fleet_stack/core/repositories/push_token_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PushDeviceState {
  final bool supported;
  final bool askedOnce;
  final bool enabledByUser;
  final bool registered;
  final String? token;

  const PushDeviceState({
    required this.supported,
    required this.askedOnce,
    required this.enabledByUser,
    required this.registered,
    required this.token,
  });

  bool get canShowBanner => supported;
  bool get canEnable => supported && !registered;
  bool get canDisable => supported && registered;
}

class PushNotificationsService {
  PushNotificationsService._();

  static final PushNotificationsService instance = PushNotificationsService._();

  static const String _kPromptAsked = 'push_prompt_asked';
  static const String _kPushEnabledByUser = 'push_enabled_by_user';
  static const String _kRegisteredToken = 'push_registered_token';
  static const String _kPushDeviceId = 'push_device_id';

  ApiClient? _api;
  PushTokenRepository? _repo;
  StreamSubscription<String>? _tokenRefreshSub;
  String? _webVapidKey;
  bool _firebaseReady = false;

  bool get _supportsPushPlatform {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  String get _platformLabel {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'unsupported';
    }
  }

  PushTokenRepository _repoOrCreate() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= PushTokenRepository(api: _api!);
    return _repo!;
  }

  Future<bool> shouldPromptAfterLogin() async {
    if (!_supportsPushPlatform) return false;
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_kPromptAsked) ?? false);
  }

  Future<void> markPromptDeclined() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPromptAsked, true);
    await prefs.setBool(_kPushEnabledByUser, false);
  }

  Future<PushDeviceState> getStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = (prefs.getString(_kRegisteredToken) ?? '').trim();
    return PushDeviceState(
      supported: _supportsPushPlatform,
      askedOnce: prefs.getBool(_kPromptAsked) ?? false,
      enabledByUser: prefs.getBool(_kPushEnabledByUser) ?? false,
      registered:
          token.isNotEmpty && (prefs.getBool(_kPushEnabledByUser) ?? false),
      token: token.isEmpty ? null : token,
    );
  }

  Future<Result<PushDeviceState>> enable({CancelToken? cancelToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPromptAsked, true);

    if (!_supportsPushPlatform) {
      return Result.fail(
        const ApiException(
          message: 'Push notifications are not available on this device.',
        ),
      );
    }

    final init = await _ensureFirebaseReady(cancelToken: cancelToken);
    if (init is Failure<void>) {
      await prefs.setBool(_kPushEnabledByUser, false);
      return Result.fail(init.cause);
    }

    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      final status = settings.authorizationStatus;
      if (status != AuthorizationStatus.authorized &&
          status != AuthorizationStatus.provisional) {
        await prefs.setBool(_kPushEnabledByUser, false);
        return Result.fail(
          const ApiException(
            message: 'Notifications permission was not granted.',
          ),
        );
      }

      final token = await _fetchMessagingToken();
      if (token == null || token.trim().isEmpty) {
        await prefs.setBool(_kPushEnabledByUser, false);
        return Result.fail(
          const ApiException(
            message: 'Could not obtain a push token on this device.',
          ),
        );
      }

      final res = await _repoOrCreate().registerToken(
        token: token.trim(),
        platform: _platformLabel,
        deviceId: await _deviceId(),
        userAgent: 'fleet_stack_flutter',
        cancelToken: cancelToken,
      );

      if (res is Failure<void>) {
        await prefs.setBool(_kPushEnabledByUser, false);
        return Result.fail(res.cause);
      }

      await prefs.setBool(_kPushEnabledByUser, true);
      await prefs.setString(_kRegisteredToken, token.trim());
      await _startTokenRefreshListener();

      return Result.ok(await getStatus());
    } catch (e) {
      await prefs.setBool(_kPushEnabledByUser, false);
      return Result.fail(
        ApiException(
          message: 'Push notifications could not be enabled on this build.',
          details: e,
        ),
      );
    }
  }

  Future<Result<void>> disable({CancelToken? cancelToken}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = (prefs.getString(_kRegisteredToken) ?? '').trim();
    if (token.isNotEmpty) {
      final res = await _repoOrCreate().unregisterToken(
        token: token,
        cancelToken: cancelToken,
      );
      if (res is Failure<void>) return Result.fail(res.cause);
    }
    await prefs.setBool(_kPromptAsked, true);
    await prefs.setBool(_kPushEnabledByUser, false);
    await prefs.remove(_kRegisteredToken);
    await _stopTokenRefreshListener();
    return Result.ok(null);
  }

  Future<void> unregisterForLogout({CancelToken? cancelToken}) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_kPushEnabledByUser) ?? false;
    final token = (prefs.getString(_kRegisteredToken) ?? '').trim();
    if (!enabled || token.isEmpty) {
      await _stopTokenRefreshListener();
      return;
    }
    final sessionToken = await TokenStorage.defaultInstance().readAccessToken();
    if (sessionToken == null || sessionToken.trim().isEmpty) {
      await _stopTokenRefreshListener();
      return;
    }
    await _repoOrCreate().unregisterToken(
      token: token,
      cancelToken: cancelToken,
    );
    await _stopTokenRefreshListener();
  }

  Future<void> syncOnAppStart() async {
    final prefs = await SharedPreferences.getInstance();
    if (!_supportsPushPlatform ||
        !(prefs.getBool(_kPushEnabledByUser) ?? false)) {
      return;
    }
    final sessionToken = await TokenStorage.defaultInstance().readAccessToken();
    if (sessionToken == null || sessionToken.trim().isEmpty) return;

    final init = await _ensureFirebaseReady();
    if (init is Failure<void>) return;

    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      final status = settings.authorizationStatus;
      if (status != AuthorizationStatus.authorized &&
          status != AuthorizationStatus.provisional) {
        return;
      }

      final token = await _fetchMessagingToken();
      if (token == null || token.trim().isEmpty) return;

      final res = await _repoOrCreate().registerToken(
        token: token.trim(),
        platform: _platformLabel,
        deviceId: await _deviceId(),
        userAgent: 'fleet_stack_flutter',
      );
      if (res is Success<void>) {
        await prefs.setString(_kRegisteredToken, token.trim());
        await _startTokenRefreshListener();
      }
    } catch (_) {
      // Best-effort sync only.
    }
  }

  Future<Result<void>> _ensureFirebaseReady({CancelToken? cancelToken}) async {
    if (_firebaseReady || Firebase.apps.isNotEmpty) {
      _firebaseReady = true;
      return Result.ok(null);
    }

    try {
      if (kIsWeb) {
        final res = await _repoOrCreate().getWebConfig(
          cancelToken: cancelToken,
        );
        if (res is Failure<PushWebConfigPayload>) {
          return Result.fail(res.cause);
        }
        final payload = (res as Success<PushWebConfigPayload>).value;
        final cfg = payload.webConfig;
        _webVapidKey = payload.vapidKey;
        await Firebase.initializeApp(
          options: FirebaseOptions(
            appId: (cfg['appId'] ?? '').toString(),
            apiKey: (cfg['apiKey'] ?? '').toString(),
            projectId: (cfg['projectId'] ?? '').toString(),
            messagingSenderId: (cfg['messagingSenderId'] ?? '').toString(),
            authDomain: (cfg['authDomain'] ?? '').toString(),
            storageBucket: (cfg['storageBucket'] ?? '').toString(),
            measurementId: (cfg['measurementId'] ?? '').toString(),
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
      _firebaseReady = true;
      return Result.ok(null);
    } catch (e) {
      return Result.fail(
        ApiException(
          message: 'Push notifications are not configured on this build yet.',
          details: e,
        ),
      );
    }
  }

  Future<String?> _fetchMessagingToken() async {
    if (kIsWeb) {
      return FirebaseMessaging.instance.getToken(vapidKey: _webVapidKey);
    }
    return FirebaseMessaging.instance.getToken();
  }

  Future<String> _deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = (prefs.getString(_kPushDeviceId) ?? '').trim();
    if (existing.isNotEmpty) return existing;

    final random = Random.secure();
    final generated =
        '${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}-'
        '${random.nextInt(1 << 32).toRadixString(16)}';
    await prefs.setString(_kPushDeviceId, generated);
    return generated;
  }

  Future<void> _startTokenRefreshListener() async {
    if (_tokenRefreshSub != null) return;
    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((
      token,
    ) async {
      if (token.trim().isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool(_kPushEnabledByUser) ?? false)) return;
      final sessionToken = await TokenStorage.defaultInstance()
          .readAccessToken();
      if (sessionToken == null || sessionToken.trim().isEmpty) return;
      final res = await _repoOrCreate().registerToken(
        token: token.trim(),
        platform: _platformLabel,
        deviceId: await _deviceId(),
        userAgent: 'fleet_stack_flutter',
      );
      if (res is Success<void>) {
        await prefs.setString(_kRegisteredToken, token.trim());
      }
    });
  }

  Future<void> _stopTokenRefreshListener() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
  }
}
