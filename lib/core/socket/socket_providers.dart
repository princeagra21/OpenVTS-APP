import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/di/app_container.dart';
import 'package:open_vts/core/socket/socket_service.dart';
import 'package:open_vts/core/diagnostics/diagnostics_providers.dart';
import 'package:open_vts/core/observability/observability_provider.dart';

/// Neutral socket dependency providers.
///
/// Feature modules should depend on these providers instead of importing
/// presentation bridge providers. This keeps socket ownership in core while the
/// remaining legacy repositories continue their gradual migration.
final coreSocketAccessTokenProvider = FutureProvider<String?>((ref) async {
  return AppContainer.instance.tokenStorage.readAccessToken();
});

final coreSocketServiceProvider = FutureProvider<SocketService>((ref) async {
  final token = await ref.watch(coreSocketAccessTokenProvider.future) ?? '';
  final service = SocketService(
    token: token,
    diagnostics: ref.watch(socketDiagnosticsProvider),
    observability: ref.watch(observabilityServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
