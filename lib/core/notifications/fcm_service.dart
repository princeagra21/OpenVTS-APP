import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:open_vts/core/notifications/local_notification_service.dart';
import 'package:open_vts/features/auth/data/repositories/push_token_repository.dart';

class FcmService {
  FcmService({required PushTokenRepository pushTokenRepository})
      : _pushTokenRepository = pushTokenRepository;

  final PushTokenRepository _pushTokenRepository;

  Future<void> initialize() async {
    await Firebase.initializeApp();
    await LocalNotificationService.initialize();
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      FirebaseMessaging.onMessage.listen(_handleForeground);
    }
  }

  Future<void> registerPushToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.trim().isEmpty) return;
    await _pushTokenRepository.registerToken(
      token: token,
      platform: Platform.isAndroid ? 'android' : 'ios',
      deviceId: Platform.isAndroid ? 'android-device' : 'ios-device',
      userAgent: Platform.isAndroid ? 'OpenVTS-Android' : 'OpenVTS-iOS',
    );
  }

  Future<void> unregisterPushToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.trim().isEmpty) return;
    await _pushTokenRepository.unregisterToken(token: token);
  }

  void _handleForeground(RemoteMessage message) {
    LocalNotificationService.show(
      title: message.notification?.title ?? 'FleetStack',
      body: message.notification?.body ?? '',
      payload: message.data,
    );
  }
}
