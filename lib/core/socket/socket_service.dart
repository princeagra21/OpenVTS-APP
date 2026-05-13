import 'dart:async';

import 'package:open_vts/core/config/app_config.dart';
import 'package:open_vts/core/socket/socket_events.dart';
import 'package:open_vts/core/diagnostics/socket_diagnostics.dart';
import 'package:open_vts/core/observability/observability_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  SocketService({
    required String token,
    String? baseUrl,
    SocketDiagnostics? diagnostics,
    ObservabilityService? observability,
  })  : _token = token,
        _diagnostics = diagnostics,
        _observability = observability,
        _baseUrl = baseUrl ?? AppConfig.fromDartDefine().baseUrl;

  final String _token;
  final String _baseUrl;
  final SocketDiagnostics? _diagnostics;
  final ObservabilityService? _observability;
  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    if (_socket != null) return;
    _observability?.addBreadcrumb('socket', 'socket_connect_requested');
    _socket = io.io(
      _baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': _token})
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .enableReconnection()
          .build(),
    );
    _socket!
      ..onConnect((_) => _diagnostics?.recordConnected())
      ..onConnectError((error) => _observability?.captureMessage(
            'socket_connect_error',
            context: <String, Object?>{'error': error.toString()},
          ))
      ..onError((error) => _observability?.captureMessage(
            'socket_error',
            context: <String, Object?>{'error': error.toString()},
          ))
      ..onDisconnect((_) => _diagnostics?.recordDisconnected())
      ..onReconnect((_) => _diagnostics?.recordReconnect())
      ..connect();
  }

  Stream<Map<String, dynamic>> stream(String event) {
    connect();
    final controller = StreamController<Map<String, dynamic>>.broadcast();

    void listener(dynamic data) {
      if (data is Map<String, dynamic>) {
        _diagnostics?.recordTelemetryReceived();
        controller.add(data);
      } else if (data is Map) {
        _diagnostics?.recordTelemetryReceived();
        controller.add(Map<String, dynamic>.from(data.cast()));
      } else {
        _observability?.addBreadcrumb(
          'socket',
          'socket_payload_ignored',
          data: <String, Object?>{'event': event, 'payloadType': data.runtimeType.toString()},
        );
      }
    }

    _socket?.on(event, listener);
    controller.onCancel = () => _socket?.off(event, listener);
    return controller.stream;
  }

  Stream<Map<String, dynamic>> allVehiclePositions() => stream(SocketEvents.telemetry);
  Stream<Map<String, dynamic>> alertStream() => stream(SocketEvents.alert);
  Stream<Map<String, dynamic>> commandResponseStream() => stream(SocketEvents.commandResponse);

  void dispose() {
    _observability?.addBreadcrumb('socket', 'socket_disposed');
    _socket?.dispose();
    _socket = null;
  }
}
