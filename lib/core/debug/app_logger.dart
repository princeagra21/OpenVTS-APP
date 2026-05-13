import 'package:flutter/foundation.dart';
import 'package:open_vts/core/security/token_redactor.dart';

class AppLogger {
  static const TokenRedactor _redactor = TokenRedactor();

  static void debug(Object? message, {int? wrapWidth}) {
    if (!kDebugMode) return;
    debugPrint(_redactor.redact(message), wrapWidth: wrapWidth);
  }

  static void info(String event, {Map<String, Object?> context = const {}}) {
    _write('INFO', event, context: context);
  }

  static void warning(String event, {Map<String, Object?> context = const {}}) {
    _write('WARN', event, context: context);
  }

  static void error(
    String event, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    _write('ERROR', event, context: {
      ...context,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    });
  }

  static void event(String event, {Map<String, Object?> context = const {}}) {
    _write('EVENT', event, context: context);
  }

  static void _write(String level, String event, {Map<String, Object?> context = const {}}) {
    if (!kDebugMode) return;
    final safeContext = _redactor.redactMap(context);
    debugPrint(_redactor.redact('[$level] $event $safeContext'));
  }
}
