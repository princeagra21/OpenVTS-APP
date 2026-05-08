import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(Object? message, {int? wrapWidth}) {
    if (!kDebugMode) return;
    debugPrint(message?.toString(), wrapWidth: wrapWidth);
  }
}